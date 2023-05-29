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
  local ctx = require('dyninput.context')
  require('dyninput').setup({
    c = {
      ['-'] = { '->', ctx.non_space_before },
    },
    cpp = {
      [','] = { ' <!>', ctx.generic_in_cpp },
      ['-'] = { '->', ctx.non_space_before },
    },
    rust = {
      [';'] = {
        { '::', ctx.rust_double_colon },
        { ': ', ctx.rust_single_colon },
      },
      ['='] = { ' => ', ctx.rust_fat_arrow },
      ['-'] = { ' -> ', ctx.rust_thin_arrow },
    },
    lua = {
      [';'] = { ':', ctx.semicolon_in_lua },
    },
    go = {
      [';'] = { ' := ', ctx.diagnostic_match('undefine') },
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
