local config = {}

function config.template_nvim()
  require('template').setup({
    temp_dir = '~/.config/nvim/template',
    author = 'glepnir',
    email = 'glephunter@gmail.com',
  })
  require('telescope').load_extension('find_template')
end

function config.guard()
  local ft = require('guard.filetype')
  ft('c,cpp'):fmt({
    cmd = 'clang-format',
    stdin = true,
    ignore_patterns = { 'neovim', 'vim' },
  })

  ft('lua'):fmt({
    cmd = 'stylua',
    args = { '-' },
    stdin = true,
    ignore_patterns = 'neovim/*%.lua',
  })
  ft('go'):fmt('lsp'):append('golines')
  ft('rust'):fmt('rustfmt')
  ft('typescript', 'javascript', 'typescriptreact', 'javascriptreact'):fmt('prettier')

  require('guard').setup()
end

return config
