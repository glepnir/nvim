local g = vim.g
vim.loader.enable()
g.mapleader = vim.keycode('<space>')
g.language = {
  'c',
  'cpp',
  'rust',
  'zig',
  'lua',
  'python',
  'proto',
  'typescript',
  'javascript',
  'tsx',
  'css',
  'scss',
  'diff',
  'dockerfile',
  'graphql',
  'html',
  'sql',
  'markdown',
  'markdown_inline',
  'json',
  'jsonc',
  'vimdoc',
  'vim',
  'cmake',
}

g.loaded_gzip = 1
g.loaded_tar = 1
g.loaded_tarPlugin = 1
g.loaded_zip = 1
g.loaded_zipPlugin = 1
g.loaded_getscript = 1
g.loaded_getscriptPlugin = 1
g.loaded_vimball = 1
g.loaded_vimballPlugin = 1
g.loaded_matchit = 1
g.loaded_2html_plugin = 1
g.loaded_rrhelper = 1
g.loaded_netrwPlugin = 1
g.loaded_matchparen = 1

local o = vim.o
o.hidden = true
o.magic = true
o.virtualedit = 'block'
o.clipboard = 'unnamedplus'
o.wildignorecase = true
o.swapfile = false
o.timeout = true
o.ttimeout = true
o.timeoutlen = 500
o.ttimeoutlen = 10
o.updatetime = 500
o.ignorecase = true
o.smartcase = true
o.cursorline = true
o.showmode = false
o.shortmess = 'aoOTIcF'
o.scrolloff = 2
o.sidescrolloff = 5
o.ruler = false
o.showtabline = 0
o.showcmd = false
o.pumheight = 15
o.pummaxwidth = 30
o.list = true
--eol:¬
o.listchars = 'tab:» ,nbsp:+,trail:·,extends:→,precedes:←,'
o.fillchars = 'trunc:…'
o.foldtext = ''
o.foldlevelstart = 99
o.undofile = true
o.linebreak = true
o.smoothscroll = true
o.smarttab = true
o.expandtab = true
o.autoindent = true
o.tabstop = 2
o.sw = 2
o.wrap = false
o.number = true
o.signcolumn = 'yes'
o.textwidth = 80
o.colorcolumn = '+0'
o.winborder = 'rounded'
o.splitright = true

o.cot = 'menu,menuone,noinsert,fuzzy,nosort,popup'
o.cia = 'kind,abbr,menu'
vim.opt.guicursor:remove({ 't:block-blinkon500-blinkoff500-TermCursor' })

vim.cmd.colorscheme(vim.env.NVIMTHEME or 'solarized')
g.health = { style = 'float' }
g.editorconfig = false

vim.api.nvim_create_autocmd('PackChanged', {
  callback = function(ev)
    local name, active = ev.data.spec.name, ev.data.active
    if name == 'nvim-treesitter' then
      if not active then
        vim.cmd.packadd('nvim-treesitter')
      end
      vim.schedule(function()
        require('nvim-treesitter').install(vim.g.language)
      end)
    end
  end,
})

vim.g.phoenix = {
  snippet = vim.fn.stdpath('config') .. '/snippets',
}

local P = {}

function P:add(specs, opts)
  if type(specs) == 'string' or (type(specs) == 'table' and specs.src) then
    specs = { specs }
  end
  opts = opts or {}
  opts.confirm = false
  vim.pack.add(specs, opts)
  return self
end

P:add('https://github.com/nvimdev/modeline.nvim')
  :add({
    'https://github.com/lewis6991/gitsigns.nvim',
    'https://github.com/nvimdev/visualizer.nvim',
    'https://github.com/nvimdev/phoenix.nvim',
    { src = 'https://github.com/nvim-treesitter/nvim-treesitter', version = 'main' },
    { src = 'https://github.com/nvim-treesitter/nvim-treesitter-textobjects', version = 'main' },
  }, {
    load = false,
  })
  :add('https://github.com/nvimdev/dired.nvim', {
    load = function()
      vim.api.nvim_create_user_command('Dired', function(data)
        vim.api.nvim_del_user_command('Dired')
        vim.cmd.packadd('dired.nvim')
        vim.cmd('Dired ' .. data.args)
      end, {
        nargs = '?',
      })
    end,
  })
  :add('https://github.com/ibhagwan/fzf-lua', {
    load = function()
      vim.api.nvim_create_user_command('FzfLua', function(data)
        vim.api.nvim_del_user_command('FzfLua')
        vim.cmd.packadd('fzf-lua')
        require('fzf-lua').setup({
          'max-perf',
          lsp = { symbols = { symbol_style = 3 } },
        })
        vim.cmd('FzfLua ' .. data.args)
      end, {
        nargs = '?',
      })
    end,
  })
  :add('https://github.com/nvimdev/indentmini.nvim', {
    load = function()
      vim.api.nvim_create_autocmd({ 'BufEnter', 'BufNewFile' }, {
        callback = function()
          vim.cmd.packadd('indentmini.nvim')
          require('indentmini').setup({
            only_current = true,
          })
        end,
      })
    end,
  })
  :add({
    'https://github.com/nvimdev/guard.nvim',
    'https://github.com/nvimdev/guard-collection',
  }, {
    load = function()
      vim.api.nvim_create_autocmd('BufReadPost', {
        once = true,
        callback = function()
          vim.cmd.packadd('guard.nvim')
          vim.cmd.packadd('guard-collection')
          local ft = require('guard.filetype')
          ft('c,cpp'):fmt({
            cmd = 'clang-format',
            args = function(bufnr)
              local f = vim.bo[bufnr].filetype == 'cpp' and '.cc-format' or '.c-format'
              return { ('--style=file:%s/%s'):format(vim.env.HOME, f) }
            end,
            stdin = true,
            ignore_patterns = { 'neovim', 'vim' },
          })

          ft('lua'):fmt({
            cmd = 'stylua',
            args = { '-' },
            stdin = true,
            ignore_patterns = 'function.*_spec%.lua',
            find = '.stylua.toml',
          })
          ft('rust'):fmt('rustfmt')
          ft('typescript', 'javascript', 'typescriptreact', 'javascriptreact'):fmt('prettier')
        end,
      })
    end,
  })
