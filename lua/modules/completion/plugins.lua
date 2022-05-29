local completion = {}
local conf = require('modules.completion.config')

completion['neovim/nvim-lspconfig'] = {
  ft = { 'go','lua','sh'},
  config = conf.nvim_lsp,
}

completion['glepnir/lspsaga.nvim'] = {
  cmd = 'Lspsaga',
}

completion['hrsh7th/nvim-cmp'] = {
  event = 'InsertEnter',
  config = conf.nvim_cmp,
  requires = {
    {'hrsh7th/cmp-nvim-lsp', after = 'nvim-lspconfig' },
    {'hrsh7th/cmp-path' , after = 'nvim-cmp'},
    {'hrsh7th/cmp-buffer', after = 'nvim-cmp' },
    {'hrsh7th/cmp-vsnip', after = 'vim-vsnip'},
  }
}

completion['hrsh7th/vim-vsnip'] = {
  event = 'InsertCharPre',
  config = conf.vim_vsnip
}

completion['windwp/nvim-autopairs'] = {
  event = 'InsertEnter',
  config = conf.auto_pairs,
}

completion['glepnir/smartinput.nvim'] = {
  ft = 'go',
  config = conf.smart_input
}

completion['mattn/vim-sonictemplate'] = {
  cmd = 'Template',
  ft = {'go','typescript','lua','javascript','vim','rust','markdown'},
  config = conf.vim_sonictemplate,
}

completion['mattn/emmet-vim'] = {
  ft = {'html','css','javascript','javascriptreact','vue','typescript','typescriptreact'},
  config = conf.emmet,
}

return completion
