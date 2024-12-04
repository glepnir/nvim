local api, completion, ffi, lsp = vim.api, vim.lsp.completion, require('ffi'), vim.lsp
local au = api.nvim_create_autocmd
local ms, libc = vim.lsp.protocol.Methods, ffi.C
local InsertCharPre = 'InsertCharPre'
ffi.cdef([[
  typedef int32_t linenr_T;
  char *ml_get(linenr_T lnum);
  bool pum_visible(void);
]])
local pumvisible = libc.pum_visible

-- completion on word which not exist in lsp client triggerCharacters
local function auto_trigger(bufnr, client)
  au(InsertCharPre, {
    buffer = bufnr,
    callback = function()
      if pumvisible() then
        return
      end
      local triggerchars = vim.tbl_get(
        client,
        'server_capabilities',
        'completionProvider',
        'triggerCharacters'
      ) or {}
      if vim.v.char:match('[%w_]') and not vim.list_contains(triggerchars, vim.v.char) then
        completion.trigger()
      end
    end,
  })
end

local function set_popup(bufnr)
  au('CompleteChanged', {
    buffer = bufnr,
    callback = function()
      local info = vim.fn.complete_info()
      if info.preview_winid and info.preview_bufnr then
        api.nvim_set_option_value('filetype', 'markdown', { buf = info.preview_bufnr })
        api.nvim_set_option_value('conceallevel', 2, { win = info.preview_winid, scope = 'local' })
        api.nvim_set_option_value(
          'concealcursor',
          'niv',
          { win = info.preview_winid, scope = 'local' }
        )
      end
    end,
  })
end

au('LspAttach', {
  callback = function(args)
    local bufnr = args.buf
    local client = lsp.get_client_by_id(args.data.client_id)
    if not client or not client:supports_method('textDocument/completion') then
      return
    end

    completion.enable(true, client.id, bufnr, {
      autotrigger = true,
      convert = function(item)
        return { abbr = item.label:gsub('%b()', ''), kind = '' }
      end,
    })
    auto_trigger(bufnr, client)
    -- set_popup(bufnr)
  end,
})

local function feedkeys(key)
  api.nvim_feedkeys(api.nvim_replace_termcodes(key, true, false, true), 'n', true)
end

local function buf_has_client(bufnr)
  return #lsp.get_clients({ bufnr = bufnr, method = ms.textDocument_completion }) > 0
end

local function is_path_related(line, col)
  if col == 0 then
    return false
  end
  local char_before_cursor = line:sub(col, col)
  return char_before_cursor:match('[/%w_%-%.~]')
end

local debounce_fn = function()
  local timer = nil --[[uv_timer_t]]
  local function safe_close()
    if timer and timer:is_active() then
      timer:stop()
      timer:close()
      timer = nil
    end
  end

  return function(key)
    timer = assert(vim.uv.new_timer())
    safe_close()
    local row, col = unpack(api.nvim_win_get_cursor(0))
    timer:start(50, 0, function()
      safe_close()
      vim.schedule(function()
        local curpos = api.nvim_win_get_cursor(0)
        if curpos[1] ~= row and curpos[2] ~= col + 1 then
          return
        end
        feedkeys(key)
      end)
    end)
  end
end

local debounce_feedkey = debounce_fn()

-- completion for directory and files
au(InsertCharPre, {
  callback = function(args)
    if pumvisible() then
      return
    end
    local bufnr = args.buf
    local ok = vim.iter({ 'terminal', 'prompt', 'help' }):any(function(v)
      return v == vim.bo[bufnr].buftype
    end)
    if ok then
      return
    end
    local char = vim.v.char
    local lnum, col = unpack(api.nvim_win_get_cursor(0))
    local line_text = ffi.string(ffi.C.ml_get(lnum))
    if char == '/' and is_path_related(line_text, col) then
      feedkeys('<C-X><C-F>')
    elseif char:match('%w') and not buf_has_client(bufnr) then
      debounce_feedkey('<C-X><C-N>')
    end
  end,
})
