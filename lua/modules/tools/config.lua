local config = {}

function config.template_nvim()
  require('template').setup({
    temp_dir = '~/.config/nvim/template',
    author = 'glepnir',
    email = 'glephunter@gmail.com',
  })
  require('telescope').load_extension('find_template')
end

function config.easyformat()
  local prettier = {
    cmd = 'prettier',
    args = { '--stdin-filepath', vim.api.nvim_buf_get_name(0) },
    stdin = true,
  }
  require('easyformat').setup({
    fmt_on_save = true,
    c = {
      cmd = 'clang-format',
      args = { '-style=file', vim.api.nvim_buf_get_name(0) },
      ignore_patterns = { 'neovim/*' },
      find = '.clang-format',
      stdin = false,
      lsp = false,
    },
    cpp = {
      cmd = 'clang-format',
      args = { '-style=file', vim.api.nvim_buf_get_name(0) },
      ignore_patterns = { 'neovim/*' },
      find = '.clang-format',
      stdin = false,
      lsp = false,
    },
    rust = {
      cmd = 'rustfmt',
      args = {},
      stdin = true,
      lsp = false,
    },
    go = {
      cmd = 'golines',
      args = { '--max-len=80', vim.api.nvim_buf_get_name(0) },
      stdin = false,
      hook = function()
        vim.lsp.buf.code_action({ context = { only = { 'source.organizeImports' } }, apply = true })
      end,
      lsp = true,
    },
    lua = {
      cmd = 'stylua',
      ignore_patterns = { '%pspec', 'neovim/*' },
      find = '.stylua.toml',
      args = { '-' },
      stdin = true,
      lsp = false,
    },
    typescript = prettier,
    typescriptreact = prettier,
    javascript = prettier,
    javascriptreact = prettier,
  })
end

function config.mut_char()
  local filters = require('mutchar.filters')
  require('mutchar').setup({
    ['c'] = {
      rules = { '-', '->' },
      filter = filters.non_space_before,
    },
    ['cpp'] = {
      rules = {
        { ',', ' <!>' },
        { '-', '->' },
      },
      filter = {
        filters.generic_in_cpp,
        filters.non_space_before,
      },
      one_to_one = true,
    },
    ['rust'] = {
      rules = {
        { ';', ': ' },
        { '-', '->' },
        { ',', '<!>' },
      },
      filter = {
        filters.semicolon_in_rust,
        filters.minus_in_rust,
        filters.generic_in_rust,
      },
      one_to_one = true,
    },
    ['lua'] = {
      rules = { ';', ':' },
      filter = filters.semicolon_in_lua,
    },
    ['go'] = {
      rules = {
        { ';', ' :=' },
        { ',', ' <-' },
      },
      filter = {
        filters.find_diagnostic_msg({ 'initial', 'undeclare' }),
        filters.go_arrow_symbol,
      },
      one_to_one = true,
    },
  })
end

function config.hop()
  local hop = require('hop')
  hop.setup({
    keys = 'asdghklqwertyuiopzxcvbnmfj',
  })
end

return config
