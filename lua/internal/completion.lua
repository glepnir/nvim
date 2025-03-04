local api, completion, lsp = vim.api, vim.lsp.completion, vim.lsp
local ms = lsp.protocol.Methods
local InsertCharPre = 'InsertCharPre'
local pumvisible = vim.fn.pumvisible
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

    completion.enable(true, client.id, bufnr, {
      autotrigger = true,
      convert = function(item)
        local kind = lsp.protocol.CompletionItemKind[item.kind] or 'u'
        local doc = item.documentation or {}
        local info, menu
        if vim.bo.filetype == 'c' then
          info = ('%s%s\n \n%s'):format(item.detail or '', item.label, doc.value or '')
          menu = ''
        end
        return {
          abbr = item.label:gsub('%b()', ''),
          kind = kind:sub(1, 1):lower(),
          kind_hlgroup = ('@lsp.type.%s'):format(kind:sub(1, 1):lower() .. kind:sub(2)),
          menu = menu,
          info = info,
        }
      end,
    })

    if #api.nvim_get_autocmds({ buffer = bufnr, event = 'InsertCharPre', group = g }) ~= 0 then
      return
    end

    api.nvim_create_autocmd(InsertCharPre, {
      buffer = bufnr,
      group = g,
      callback = function()
        if tonumber(pumvisible()) == 1 then
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
      desc = 'completion on character which not exist in lsp client triggerCharacters',
    })

    api.nvim_create_autocmd(InsertCharPre, {
      buffer = bufnr,
      group = g,
      callback = function()
        vim.g._ts_force_sync_parsing = tonumber(pumvisible()) == 1
      end,
    })

    api.nvim_create_autocmd('CompleteDone', {
      buffer = bufnr,
      group = g,
      callback = function()
        vim.g._ts_force_sync_parsing = false
      end,
    })
  end,
})
