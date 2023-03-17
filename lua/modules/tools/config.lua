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
  local configs = require('easyformat.config')
  configs.lua = {
    ignore_patterns = { '%pspec', 'neovim/*' },
    find = nil,
  }
  configs.c = {
    ignore_patterns = { 'neovim/*' },
  }
  configs.use_default({
    'cpp',
    'go',
    'rust',
    'javascriptreact',
  })
  require('easyformat').setup({
    fmt_on_save = true,
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
