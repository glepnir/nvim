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
    ignore_patterns = 'function.*_spec%.lua',
    find = '.stylua.toml',
  })
  ft('go'):fmt('lsp'):append('golines')
  ft('rust'):fmt('rustfmt')
  ft('typescript', 'javascript', 'typescriptreact', 'javascriptreact'):fmt('prettier')
  -- hack when save diagnostic is missing
  vim.api.nvim_create_autocmd('User', {
    pattern = 'GuardFmt',
    callback = function(args)
      if args.data.status == 'done' then
        vim.diagnostic.show()
      end
    end,
  })
end

return config
