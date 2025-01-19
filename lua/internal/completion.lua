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
local g = api.nvim_create_augroup('glepnir/completion', { clear = true })

-- completion on word which not exist in lsp client triggerCharacters
local function auto_trigger(bufnr, client)
  au(InsertCharPre, {
    buffer = bufnr,
    group = g,
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
        vim.schedule(function()
          completion.trigger()
        end)
      end
    end,
  })
end

au('LspAttach', {
  group = g,
  callback = function(args)
    local bufnr = args.buf
    local client = lsp.get_client_by_id(args.data.client_id)
    if not client or not client:supports_method('textDocument/completion') then
      return
    end

    completion.enable(true, client.id, bufnr, {
      autotrigger = true,
      convert = function(item)
        return { abbr = item.label:gsub('%b()', ''), kind = '', kind_hlgroup = '' }
      end,
    })

    if #api.nvim_get_autocmds({ buffer = bufnr, event = 'InsertCharPre', group = g }) == 0 then
      auto_trigger(bufnr, client)
    end
  end,
})

require('internal.server').setup()
