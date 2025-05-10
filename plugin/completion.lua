local api = vim.api
local au = api.nvim_create_autocmd

au('LspAttach', {
  group = api.nvim_create_augroup('glepnir.completion', { clear = true }),
  callback = function(args)
    local lsp = vim.lsp
    local completion = lsp.completion
    local ms = lsp.protocol.Methods

    local bufnr = args.buf
    local client = lsp.get_client_by_id(args.data.client_id)
    if not client or not client:supports_method(ms.textDocument_completion) then
      return
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
      autotrigger = not vim.env.DEBUG_COMPLETION and true or { any = true },
      convert = function(item)
        local kind = lsp.protocol.CompletionItemKind[item.kind] or 'u'
        return {
          abbr = item.label:gsub('%b()', ''),
          kind = kind:sub(1, 1):lower(),
          menu = '',
        }
      end,
    })

    au('CompleteChanged', {
      buffer = bufnr,
      callback = function()
        local info = vim.fn.complete_info({ 'selected' })
        if info.preview_bufnr and vim.bo[info.preview_bufnr].filetype == '' then
          vim.bo[info.preview_bufnr].filetype = 'markdown'
          vim.wo[info.preview_winid].conceallevel = 2
          vim.wo[info.preview_winid].concealcursor = 'niv'
        end
      end,
    })
  end,
})
