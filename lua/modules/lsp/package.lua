local function diag_config()
  --disable diagnostic in neovim test file *_spec.lua
  vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('DisableInSpec', { clear = true }),
    pattern = 'lua',
    callback = function(opt)
      local fname = vim.api.nvim_buf_get_name(opt.buf)
      if fname:find('%w_spec%.lua') then
        vim.diagnostic.disable(opt.buf)
      end
    end,
  })
end

packadd({
  'neovim/nvim-lspconfig',
  dev = true,
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
    diag_config()
    require('modules.lsp.backend')
    require('modules.lsp.frontend')
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
