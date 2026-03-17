local api = vim.api
local au = api.nvim_create_autocmd
local g = api.nvim_create_augroup('glepnir.completion', { clear = true })
local phoenix_id = 0

au('LspAttach', {
  group = g,
  callback = function(args)
    local lsp = vim.lsp
    local completion = lsp.completion
    local ms = lsp.protocol.Methods
    local CompletionItemKind = lsp.protocol.CompletionItemKind

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
        local cpp = vim.bo.filetype == 'c' or vim.bo.filetype == 'cpp'
        local res = {
          kind = kind:sub(1, 1):lower(),
          menu = '',
        }
        -- hack for c/cpp
        if
          (item.kind == CompletionItemKind.Function or item.kind == CompletionItemKind.Method)
          and cpp
          and not item.textEdit.newText:find('%)$')
        then
          res.word = item.insertText .. '()'
        end
        return res
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
        callback = function()
          local item =
            vim.tbl_get(vim.v.completed_item, 'user_data', 'nvim', 'lsp', 'completion_item')
          if not item then
            return
          end

          if
            (item.kind == CompletionItemKind.Function or item.kind == CompletionItemKind.Method)
            and item.label:match('%(.+%)') ~= nil
          then
            vim.schedule(function()
              local mode = api.nvim_get_mode().mode
              if mode:match('^[is]') then
                local line = api.nvim_get_current_line()
                local lnum, col = unpack(api.nvim_win_get_cursor(0))
                local prevchar = line:sub(col, col)
                if prevchar ~= '(' and prevchar ~= ')' then
                  line = line:sub(1, col) .. '()' .. line:sub(col + 1, #line)
                  api.nvim_buf_set_text(0, lnum - 1, 0, lnum - 1, -1, { line })
                  api.nvim_feedkeys(
                    api.nvim_replace_termcodes('<Right>', true, false, true),
                    'n',
                    false
                  )
                elseif prevchar == ')' then
                  api.nvim_feedkeys(
                    api.nvim_replace_termcodes('<Left>', true, false, true),
                    'n',
                    false
                  )
                end

                vim.defer_fn(function()
                  lsp.buf.signature_help()
                end, 1)
              end
            end)
          end
        end,
        desc = 'Auto show signature help when compeltion done',
      })
    end
  end,
})
