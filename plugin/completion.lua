local api = vim.api
local au = api.nvim_create_autocmd
local g = api.nvim_create_augroup('glepnir.completion', { clear = true })
local phoenix_id = 0

local function is_cpp()
  local ft = vim.bo.filetype
  return ft == 'cpp' or ft == 'cxx' or ft == 'cc' or ft == 'hpp'
end

local function is_cpp_template(item)
  -- labelDetails.detail: "<class Tp>(...)"
  local detail = vim.tbl_get(item, 'labelDetails', 'detail')
  if detail and detail:match('<.->') then
    return true
  end

  -- abbr: "foo<class T>(...)"
  local abbr = vim.v.completed_item.abbr
  if abbr and abbr:match('<.->') then
    return true
  end

  -- label fallback
  if item.label and item.label:match('<.->') then
    return true
  end
  return false
end

local function on_complete_done(args)
  local lsp = vim.lsp
  local CompletionItemKind = lsp.protocol.CompletionItemKind

  local item = vim.tbl_get(vim.v.completed_item, 'user_data', 'nvim', 'lsp', 'completion_item')
  if not item then
    return
  end

  if item.kind ~= CompletionItemKind.Function and item.kind ~= CompletionItemKind.Method then
    return
  end

  local mode = api.nvim_get_mode().mode
  if not mode:match('^[is]') then
    return
  end

  local line = api.nvim_get_current_line()
  local lnum, col = unpack(api.nvim_win_get_cursor(0))
  local prevchar = line:sub(col, col)

  if prevchar == '(' then
    vim.defer_fn(function()
      lsp.buf.signature_help({ title = '' })
    end, 1)
    return
  end

  if prevchar == ')' then
    return
  end

  local is_template = false

  if is_cpp() then
    is_template = is_cpp_template(item)

    if item.insertTextFormat == 2 then
      local text = item.insertText or (item.textEdit and item.textEdit.newText) or ''
      if text:match('<%$') then
        is_template = false
      end
    end

    if prevchar == '<' then
      is_template = false
    end
  end

  local has_params = nil

  if item.insertTextFormat == 2 then
    local text = item.insertText or (item.textEdit and item.textEdit.newText) or ''
    local inside = text:match('%((.-)%)')
    if inside then
      has_params = inside:match('%$') ~= nil
    end
  end

  if has_params == nil then
    local inside = item.label:match('%((.-)%)')
    if inside then
      has_params = #inside > 0
    end
  end

  if is_template then
    line = line:sub(1, col) .. '<>()' .. line:sub(col + 1)
  else
    line = line:sub(1, col) .. '()' .. line:sub(col + 1)
  end

  api.nvim_buf_set_text(0, lnum - 1, 0, lnum - 1, -1, { line })

  local right = api.nvim_replace_termcodes('<Right>', true, false, true)
  if is_template then
    api.nvim_feedkeys(right, 'n', false)
    return
  end

  if has_params == true then
    api.nvim_feedkeys(right, 'n', false)
    vim.defer_fn(function()
      lsp.buf.signature_help({ title = '' })
    end, 1)
  elseif has_params == false then
    api.nvim_feedkeys(right .. right, 'n', false)
  else
    api.nvim_feedkeys(right, 'n', false)

    vim.defer_fn(function()
      local c = lsp.get_client_by_id(vim.v.completed_item.user_data.nvim.lsp.client_id)
      if not c then
        return
      end

      local win = api.nvim_get_current_win()
      local params = vim.lsp.util.make_position_params(win, c.offset_encoding)

      c:request(lsp.protocol.Methods.textDocument_signatureHelp, params, function(err, result)
        vim.schedule(function()
          if err or not result or not result.signatures or #result.signatures == 0 then
            api.nvim_feedkeys(right, 'n', false)
            return
          end

          local active_idx = (result.activeSignature or 0) + 1
          local sig = result.signatures[active_idx] or result.signatures[1]

          if not sig or not sig.parameters or #sig.parameters == 0 then
            api.nvim_feedkeys(right, 'n', false)
          else
            lsp.buf.signature_help({ title = '' })
          end
        end)
      end, args.buf)
    end, 1)
  end
end

au('LspAttach', {
  group = g,
  callback = function(args)
    local lsp = vim.lsp
    local completion = lsp.completion
    local ms = lsp.protocol.Methods

    local bufnr = args.buf
    local client = lsp.get_client_by_id(args.data.client_id)
    if not client or not client:supports_method(ms.textDocument_completion) then
      return
    end
    if client.name == 'phoenix' then
      phoenix_id = client.id
    end

    if not vim.env.DEBUG_COMPLETION then
      local chars = client.server_capabilities.completionProvider.triggerCharacters
      if chars then
        for i = string.byte('a'), string.byte('z') do
          if not vim.list_contains(chars, string.char(i)) then
            table.insert(chars, string.char(i))
          end
        end

        for i = string.byte('A'), string.byte('Z') do
          if not vim.list_contains(chars, string.char(i)) then
            table.insert(chars, string.char(i))
          end
        end
      end
    end

    completion.enable(true, client.id, bufnr, {
      -- autotrigger = not vim.env.DEBUG_COMPLETION and true or { any = true },
      autotrigger = true,
      convert = function(item)
        local kind = lsp.protocol.CompletionItemKind[item.kind] or 'u'
        return {
          kind = kind:sub(1, 1):lower(),
          menu = '',
        }
      end,
      cmp = function(a, b)
        local item_a = a.user_data.nvim.lsp.completion_item
        local item_b = b.user_data.nvim.lsp.completion_item

        local is_snip_a = item_a.kind == lsp.protocol.CompletionItemKind.Snippet
        local is_snip_b = item_b.kind == lsp.protocol.CompletionItemKind.Snippet

        if is_snip_a ~= is_snip_b then
          return is_snip_a
        end

        local client_a = a.user_data.nvim.lsp.client_id
        local client_b = b.user_data.nvim.lsp.client_id
        local prio_a = client_a == phoenix_id and 999 or 1
        local prio_b = client_b == phoenix_id and 999 or 1
        if prio_a ~= prio_b then
          return prio_a < prio_b
        end

        return (item_a.sortText or item_a.label) < (item_b.sortText or item_b.label)
      end,
    })

    if
      #api.nvim_get_autocmds({
        buffer = bufnr,
        event = { 'CompleteDone' },
        group = g,
      }) == 0
    then
      au('CompleteDone', {
        buffer = bufnr,
        group = g,
        callback = on_complete_done,
        desc = 'Auto-insert parens, check params, show signature help',
      })
    end
  end,
})
