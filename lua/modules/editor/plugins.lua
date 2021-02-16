local editor = {}
local conf = require('modules.editor.config')

editor['Raimondi/delimitMate'] = {
  event = 'InsertEnter *',
  config = conf.delimimate,
}

editor['rhysd/accelerated-jk'] = {
  opt = true
}

editor['norcalli/nvim-colorizer.lua'] = {
  ft = { 'html','css','sass','vim','typescript','typescriptreact'},
  config = conf.nvim_colorizer
}

editor['itchyny/vim-cursorword'] = {
  event = {'BufReadPre *','BufNewFile *'},
  config = conf.vim_cursorwod
}

editor['hrsh7th/vim-eft'] = {
  opt = true,
  config = function()
    vim.g.eft_ignorecase = true
  end
}

editor['mhinz/vim-signify'] = {
  event = {'BufReadPre *','BufNewFile *'},
  config = conf.vim_signify
}

editor['iamcco/markdown-preview.nvim'] = {
  ft = 'markdown',
  config = function ()
    vim.g.mkdp_auto_start = 0
  end
}

editor['brooth/far.vim'] = {
  cmd = {'Far','Farp'},
  config = function ()
    vim.g['far#source'] = 'rg'
  end
}

editor['kana/vim-operator-replace'] = {
  event = 'BufRead *',
  requires = 'kana/vim-operator-user'
}

editor['rhysd/vim-operator-surround'] = {
  event = 'BufRead *',
  requires = 'kana/vim-operator-user'
}

editor['kana/vim-niceblock']  = {
  event = 'BufRead *',
  setup = conf.vim_niceblock
}

editor['kana/vim-smartchr'] = {
  ft = 'go',
  config = conf.vim_smartchar
}

return editor
