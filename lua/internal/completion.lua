local api, completion, ffi, lsp = vim.api, vim.lsp.completion, require('ffi'), vim.lsp
local au = api.nvim_create_autocmd
local ms = vim.lsp.protocol.Methods

ffi.cdef([[
  typedef int32_t linenr_T;
  char *ml_get(linenr_T lnum);
]])

local function has_word_before(triggerCharacters)
  local lnum, col = unpack(api.nvim_win_get_cursor(0))
  if col == 0 then
    return false
  end
  local line_text = ffi.string(ffi.C.ml_get(lnum))
  local char_before_cursor = line_text:sub(col, col)
  local result = char_before_cursor:match('[%w_]')
    or vim.tbl_contains(triggerCharacters, char_before_cursor)
  return result
end

local function auto_trigger(bufnr)
  au({ 'TextChangedI' }, {
    buffer = bufnr,
    callback = function(args)
      local client = lsp.get_clients({ bufnr = args.buf, method = ms.textDocument_completion })[1]
      local triggerchars =
        vim.tbl_get(client, 'server_capabilities', 'completionProvider', 'triggerCharacters')
      if has_word_before(triggerchars) then
        completion.trigger()
      end
    end,
  })
end

au('LspAttach', {
  callback = function(args)
    local bufnr = args.buf
    local client_id = args.data.client_id
    completion.enable(true, client_id, bufnr, {})
    auto_trigger(bufnr)
  end,
})

local function key_with_disable_textchangedi(key)
  -- Add the TextChangedI to eventignore avoid confirm completion thne insert
  -- text trigger TextChangedI again.
  vim.opt.eventignore:append('TextChangedI')
  api.nvim_feedkeys(api.nvim_replace_termcodes(key, true, false, true), 'n', true)
  -- reset in next eventloop
  vim.defer_fn(function()
    vim.opt.eventignore:remove('TextChangedI')
  end, 0)
end

return {
  key_with_disable_textchangedi = key_with_disable_textchangedi,
}
