local api, completion, lsp = vim.api, vim.lsp.completion, vim.lsp
local ms = lsp.protocol.Methods
local g = api.nvim_create_augroup('glepnir.completion', { clear = true })

vim.opt.cot = 'menu,menuone,noinsert,fuzzy,popup'
vim.opt.cia = 'kind,abbr,menu'

api.nvim_create_autocmd('CompleteChanged', {
  callback = function()
    local info = vim.fn.complete_info({ 'selected' })
    if info.preview_bufnr then
      vim.bo[info.preview_bufnr].filetype = 'markdown'
      vim.wo[info.preview_winid].conceallevel = 2
      vim.wo[info.preview_winid].concealcursor = 'niv'
      vim.wo[info.preview_winid].wrap = true
    end
  end,
})

api.nvim_create_autocmd('LspAttach', {
  group = g,
  callback = function(args)
    local bufnr = args.buf
    local client = lsp.get_client_by_id(args.data.client_id)
    if not client or not client:supports_method(ms.textDocument_completion) then
      return
    end
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

    completion.enable(true, client.id, bufnr, {
      autotrigger = true,
      convert = function(item)
        local kind = lsp.protocol.CompletionItemKind[item.kind] or 'u'
        local doc = item.documentation or {}
        local info
        if vim.bo.filetype == 'c' then
          info = ('%s%s\n \n%s'):format(item.detail or '', item.label, doc.value or '')
        end
        return {
          abbr = item.label:gsub('%b()', ''),
          kind = kind:sub(1, 1):lower(),
          menu = '',
          info = info and info:gsub('\n+%s*\n$', '') or nil,
        }
      end,
    })

    api.nvim_create_autocmd('TextChangedP', {
      buffer = bufnr,
      group = g,
      command = 'let g:_ts_force_sync_parsing = v:true',
    })

    api.nvim_create_autocmd('CompleteDone', {
      buffer = bufnr,
      group = g,
      command = 'let g:_ts_force_sync_parsing = v:false',
    })
  end,
})
