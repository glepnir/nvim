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
  }
  configs.c = {
    ignore_patterns = { 'neovim' },
  }
  configs.cpp = {
    ignore_patterns = { 'neovim' },
  }
  configs.use_default({
    'go',
    'rust',
    'javascript',
    'javascriptreact',
  })
  require('easyformat').setup({
    fmt_on_save = true,
  })
  exec_filetype('EasyFormat')
end

function config.dyninput()
  local rs = require('dyninput.lang.rust')
  local ms = require('dyninput.lang.misc')
  require('dyninput').setup({
    c = {
      ['-'] = {
        { '->', ms.c_struct_pointer },
        { '_', ms.snake_case },
      },
    },
    cpp = {
      [','] = { ' <!>', ms.generic_in_cpp },
      ['-'] = {
        { '->', ms.c_struct_pointer },
        { '_', ms.snake_case },
      },
    },
    rust = {
      [';'] = {
        { '::', rs.double_colon },
        { ': ', rs.single_colon },
      },
      ['='] = { ' => ', rs.fat_arrow },
      ['-'] = {
        { ' -> ', rs.thin_arrow },
        { '_', ms.snake_case },
      },
      ['\\'] = { '|!| {}', rs.closure_fn },
    },
    lua = {
      [';'] = { ':', ms.semicolon_in_lua },
      ['-'] = { '_', ms.snake_case },
    },
    go = {
      [';'] = {
        { ' := ', ms.go_variable_define },
        { ': ', ms.go_struct_field },
      },
      ['-'] = { '_', ms.snake_case },
    },
  })

  exec_filetype('dyninput')
end

function config.hop()
  local hop = require('hop')
  hop.setup({
    keys = 'asdghklqwertyuiopzxcvbnmfj',
  })
end

return config
