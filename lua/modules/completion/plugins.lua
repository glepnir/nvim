local package = require('core.pack').package
local conf = require('modules.completion.config')

package {'neovim/nvim-lspconfig',
  ft = { 'go','lua','sh','rust','c'},
  config = conf.nvim_lsp,
}

package {'~/Workspace/lspsaga.nvim', cmd = 'Lspsaga',}

package {'hrsh7th/nvim-cmp',
  event = 'InsertEnter',
  config = conf.nvim_cmp,
  requires = {
    {'hrsh7th/cmp-nvim-lsp', after = 'nvim-lspconfig' },
    {'hrsh7th/cmp-path' , after = 'nvim-cmp'},
    {'hrsh7th/cmp-buffer', after = 'nvim-cmp' },
    {'saadparwaiz1/cmp_luasnip', after = "LuaSnip" },
  },
}

package {"L3MON4D3/LuaSnip",event = 'InsertCharPre',config = conf.lua_snip }

package {'windwp/nvim-autopairs',event = 'InsertEnter', config = conf.auto_pairs}

package {'mattn/vim-sonictemplate',
  cmd = 'Template',
  ft = {'go','typescript','lua','javascript','vim','rust','markdown'},
  config = conf.vim_sonictemplate,
}

package {'mattn/emmet-vim',
  ft = {'html','css','javascript','javascriptreact','vue','typescript','typescriptreact'},
  config = conf.emmet,
}
