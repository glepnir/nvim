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

package({ '~/Workspace/coman.nvim', after = 'nvim-treesitter' })

package({ '~/Workspace/template.nvim', ft = { 'go', 'lua', 'rust' }, config = conf.template_nvim })
