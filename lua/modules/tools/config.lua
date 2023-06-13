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
  local c = ft('c')
  c:fmt('clang-format')
  ft('lua'):fmt('stylua')
  ft('go'):fmt('lsp'):append('golines')
  ft('rust'):fmt('rustfmt')

  for _, item in ipairs({ 'typescript', 'javascript', 'typescriptreact', 'javascriptreact' }) do
    ft(item):fmt('prettier')
  end

  require('guard').setup()
  exec_filetype('Guard')
end

function config.dyninput()
  local rs = require('dyninput.lang.rust')
  local ms = require('dyninput.lang.misc')
  require('dyninput').setup({
    c = {
      ['-'] = { '->', ms.c_struct_pointer },
    },
    cpp = {
      [','] = { ' <!>', ms.generic_in_cpp },
      ['-'] = { '->', ms.c_struct_pointer },
    },
    rust = {
      [';'] = {
        { '::', rs.double_colon },
        { ': ', rs.single_colon },
      },
      ['='] = { ' => ', rs.fat_arrow },
      ['-'] = { ' -> ', rs.thin_arrow },
      ['\\'] = { '|!| {}', rs.closure_fn },
    },
    lua = {
      [';'] = { ':', ms.semicolon_in_lua },
    },
    go = {
      [';'] = {
        { ' := ', ms.go_variable_define },
        { ': ', ms.go_struct_field },
      },
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
