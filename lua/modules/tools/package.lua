local package = require('core.pack').package
local conf = require('modules.tools.config')

package({
  'kristijanhusak/vim-dadbod-ui',
  cmd = { 'DBUIToggle', 'DBUIAddConnection', 'DBUI', 'DBUIFindBuffer', 'DBUIRenameBuffer' },
  config = conf.vim_dadbod_ui,
  dependencies = { 'tpope/vim-dadbod' },
})

package({ 'coman.nvim', dev = true, event = 'BufRead' })

package({ 'template.nvim', dev = true, ft = { 'c', 'lua', 'go' }, config = conf.template_nvim })
