local package = require('core.pack').package
local conf = require('modules.tools.config')

package {'kristijanhusak/vim-dadbod-ui',
  cmd = {'DBUIToggle','DBUIAddConnection','DBUI','DBUIFindBuffer','DBUIRenameBuffer'},
  config = conf.vim_dadbod_ui,
  requires = {{'tpope/vim-dadbod',opt = true}}
}

package {'editorconfig/editorconfig-vim',
  ft = { 'go','typescript','javascript','vim','rust','zig','c','cpp' }
}

package {'glepnir/prodoc.nvim', event = 'BufReadPre'}

package {'liuchengxu/vista.vim', cmd = 'Vista', config = conf.vim_vista }

package {'brooth/far.vim',
  cmd = {'Far','Farp'},
  config = function ()
    vim.g['far#source'] = 'rg'
  end
}

package {'~/Workspace/template.nvim/', config = conf.template_nvim}

package {'~/Workspace/dogic-nvim'}
