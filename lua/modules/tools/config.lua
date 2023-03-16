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
  local get_config = require('easyformat.config').get_config
  local configs =
    get_config({ 'c', 'cpp', 'lua', 'rust', 'go', 'javascriptreact', 'typescriptreact' })
  local params = vim.tbl_extend('keep', {
    fmt_on_save = true,
  }, configs)
  require('easyformat').setup(params)
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
