local g = vim.g
vim.loader.enable()
g.mapleader = vim.keycode('<space>')

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
o.pumborder = 'rounded'
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
-- reset to 2 in dashboard.lua lnum 273
o.laststatus = 0
o.cot = 'menu,menuone,noinsert,fuzzy,nosort,popup'
o.cia = 'kind,abbr,menu'
vim.opt.guicursor:remove({ 't:block-blinkon500-blinkoff500-TermCursor' })

vim.cmd.colorscheme('eink')
g.health = { style = 'float' }
g.editorconfig = false
g._lang = {
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
  'vimdoc',
  'vim',
  'cmake',
}

vim.api.nvim_create_autocmd('PackChanged', {
  callback = function(ev)
    local name, active = ev.data.spec.name, ev.data.active
    if name == 'nvim-treesitter' then
      if not active then
        vim.cmd.packadd('nvim-treesitter')
      end
      local nts = require('nvim-treesitter')
      nts.install(g.lang, { summary = true })
      nts.update(nil, { summary = true })
    end
  end,
})

g.phoenix = {
  snippet = vim.fn.stdpath('config') .. '/snippets',
}

local P = {}

local function normalize_url(s)
  return s:match('^https?://') and s or 'https://github.com/' .. s
end

local function normalize_spec(spec)
  if type(spec) == 'string' then
    return normalize_url(spec)
  end
  if spec.src then
    return vim.tbl_extend('force', spec, { src = normalize_url(spec.src) })
  end
  return spec
end

local function ensure_list(specs)
  return (type(specs) == 'string' or (type(specs) == 'table' and specs.src)) and { specs } or specs
end

local function on_cmd(cmd, pkg_name, setup_fn)
  return function()
    vim.api.nvim_create_user_command(cmd, function(data)
      vim.api.nvim_del_user_command(cmd)
      vim.cmd.packadd(pkg_name)
      if setup_fn then
        setup_fn()
      end
      vim.cmd(('%s %s'):format(cmd, data.args))
    end, { nargs = '?' })
  end
end

local function on_event(events, pkg_name, setup_fn)
  return function()
    vim.api.nvim_create_autocmd(events, {
      once = true,
      callback = function()
        for _, p in ipairs(ensure_list(pkg_name)) do
          vim.cmd.packadd(p)
        end
        if setup_fn then
          setup_fn()
        end
      end,
    })
  end
end

function P:add(specs, opts)
  specs = vim.tbl_map(normalize_spec, ensure_list(specs))
  vim.pack.add(specs, vim.tbl_extend('keep', opts or {}, { confirm = false }))
  return self
end

P:add({
  'nvimdev/modeline.nvim',
  'lewis6991/gitsigns.nvim',
  'nvimdev/visualizer.nvim',
  'nvimdev/phoenix.nvim',
  { src = 'nvim-treesitter/nvim-treesitter', version = 'main' },
  { src = 'nvim-treesitter/nvim-treesitter-textobjects', version = 'main' },
}, { load = false })
  :add('nvimdev/dired.nvim', {
    load = on_cmd('Dired', 'dired.nvim'),
  })
  :add('ibhagwan/fzf-lua', {
    load = on_cmd('FzfLua', 'fzf-lua', function()
      require('fzf-lua').setup({
        'max-perf',
        lsp = { symbols = { symbol_style = 3 } },
      })
    end),
  })
  :add('nvimdev/indentmini.nvim', {
    load = on_event({ 'BufEnter', 'BufNewFile' }, 'indentmini.nvim', function()
      require('indentmini').setup({ only_current = true })
    end),
  })
  :add({ 'nvimdev/guard.nvim', 'nvimdev/guard-collection' }, {
    load = on_event('BufReadPost', { 'guard.nvim', 'guard-collection' }, function()
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
    end),
  })
