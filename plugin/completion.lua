local api = vim.api
local au = api.nvim_create_autocmd
local g = api.nvim_create_augroup('glepnir.completion', { clear = true })

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
    })

    if
      #api.nvim_get_autocmds({
        buffer = bufnr,
        event = { 'CompleteChanged' },
        group = g,
      }) == 0
    then
      au('CompleteChanged', {
        buffer = bufnr,
        group = g,
        callback = function()
          local info = vim.fn.complete_info({ 'selected' })
          if info.preview_bufnr and vim.bo[info.preview_bufnr].filetype == '' then
            vim.bo[info.preview_bufnr].filetype = 'markdown'
            vim.wo[info.preview_winid].conceallevel = 2
            vim.wo[info.preview_winid].concealcursor = 'niv'
          end
        end,
      })

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
            item.kind == 3
            and item.insertTextFormat == lsp.protocol.InsertTextFormat.Snippet
            and (item.textEdit ~= nil or item.insertText ~= nil)
          then
            vim.schedule(function()
              if api.nvim_get_mode().mode == 's' then
                lsp.buf.signature_help()
              end
            end)
          end
        end,
        desc = 'Auto show signature help when compeltion done',
      })
    end
  end,
})
