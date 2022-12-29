local package = require('core.pack').package
local conf = require('modules.tools.config')

package({
  'kristijanhusak/vim-dadbod-ui',
  cmd = { 'DBUIToggle', 'DBUIAddConnection', 'DBUI', 'DBUIFindBuffer', 'DBUIRenameBuffer' },
  config = conf.vim_dadbod_ui,
  requires = { { 'tpope/vim-dadbod', opt = true } },
})

package({
  'editorconfig/editorconfig-vim',
  ft = { 'go', 'typescript', 'javascript', 'vim', 'rust', 'zig', 'c', 'cpp' },
})

package({ 'coman.nvim', dev = true, event = 'BufRead' })

package({ 'template.nvim', dev = true, ft = {'c', 'lua','go'}, config = conf.template_nvim })
