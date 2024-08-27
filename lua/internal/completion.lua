local api, completion, ffi, lsp = vim.api, vim.lsp.completion, require('ffi'), vim.lsp
local au, vimstate = api.nvim_create_autocmd, vim.fn.state
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
      if pumvisible() or vimstate('m') == 'm' then
        return
      end
      local triggerchars = vim.tbl_get(
        client,
        'server_capabilities',
        'completionProvider',
        'triggerCharacters'
      ) or {}
      if not vim.list_contains(triggerchars, vim.v.char) then
        completion.trigger()
      end
    end,
  })
end

au('LspAttach', {
  callback = function(args)
    local bufnr = args.buf
    local client_id = args.data.client_id
    completion.enable(true, client_id, bufnr, {
      autotrigger = true,
      convert = function(item)
        return { abbr = item.label:gsub('%b()', '') }
      end,
    })
    local client = lsp.get_client_by_id(client_id)
    if not client then
      return
    end
    auto_trigger(bufnr, client)
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

-- completion for directory and files
au(InsertCharPre, {
  callback = function(args)
    if pumvisible() or vimstate('m') == 'm' then
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
    elseif not char:match('%s') and not buf_has_client(bufnr) then
      feedkeys('<C-X><C-N>')
    end
  end,
})
