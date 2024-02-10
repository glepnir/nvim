packadd({
  'neovim/nvim-lspconfig',
  ft = {
    'go',
    'lua',
    'sh',
    'rust',
    'c',
    'cpp',
    'zig',
    'python',
    'javascript',
    'javascriptreact',
    'typescript',
    'typescriptreact',
    'json',
  },
  config = function()
    local i = '■'
    vim.diagnostic.config({ signs = { text = { i, i, i, i } } })
    require('modules.lsp.backend')
    require('modules.lsp.frontend')

    -- auto kill server when no buffer attach after a while
    local debounce
    vim.api.nvim_create_autocmd('LspDetach', {
      callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if not client or #client.attached_buffers > 0 then
          return
        end

        if debounce and debounce:is_active() then
          debounce:stop()
          debounce:close()
          debounce = nil
        end

        debounce:start(5000, 0, function()
          vim.schedule(function()
            pcall(vim.lsp.stop_client, args.data.client_id, true)
          end)
        end)
      end,
    })
  end,
})

packadd({
  'nvimdev/lspsaga.nvim',
  event = 'LspAttach',
  dev = true,
  config = function()
    require('lspsaga').setup({
      symbol_in_winbar = {
        hide_keyword = true,
        folder_level = 0,
      },
      lightbulb = {
        sign = false,
      },
      outline = {
        layout = 'float',
      },
    })
  end,
})

packadd({
  'nvimdev/epo.nvim',
  event = 'LspAttach',
  dev = true,
  config = function()
    require('epo').setup({})
  end,
})
