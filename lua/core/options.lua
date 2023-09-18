local opt = vim.opt

opt.termguicolors = true
opt.hidden = true
opt.magic = true
opt.virtualedit = 'block'
opt.clipboard = 'unnamedplus'
opt.wildignorecase = true
opt.swapfile = false

opt.history = 2000
opt.timeout = true
opt.ttimeout = true
opt.timeoutlen = 500
opt.ttimeoutlen = 10
opt.updatetime = 100
opt.redrawtime = 1500
opt.ignorecase = true
opt.smartcase = true
opt.infercase = true
opt.cursorline = true

if vim.fn.executable('rg') == 1 then
  opt.grepformat = '%f:%l:%c:%m,%f:%l:%m'
  opt.grepprg = 'rg --vimgrep --no-heading --smart-case'
end

opt.completeopt = 'menu,menuone,noselect'
opt.showmode = false
opt.shortmess = 'aoOTIcF'
opt.scrolloff = 2
opt.sidescrolloff = 5
opt.ruler = false
opt.showtabline = 0
opt.winwidth = 30
opt.pumheight = 15
opt.showcmd = false

opt.cmdheight = 0
opt.laststatus = 3
opt.list = true

opt.listchars = 'tab:»·,nbsp:+,trail:·,extends:→,precedes:←'
opt.pumblend = 10
opt.winblend = 0
opt.undofile = true

opt.smarttab = true
opt.expandtab = true
opt.autoindent = true
opt.tabstop = 2
opt.shiftwidth = 2

opt.foldlevelstart = 99
opt.foldmethod = 'marker'

opt.splitright = true
opt.wrap = false

opt.number = true
opt.signcolumn = 'yes'
opt.spelloptions = 'camel'

opt.textwidth = 100
opt.colorcolumn = '100'

local function get_signs()
  local buf = vim.api.nvim_get_current_buf()
  return vim.tbl_map(function(sign)
    return vim.fn.sign_getdefined(sign.name)[1]
  end, vim.fn.sign_getplaced(buf, { group = '*', lnum = vim.v.lnum })[1].signs)
end

local function fill_space(count)
  return '%#StcFill#' .. (' '):rep(count) .. '%*'
end

function _G.show_stc()
  local sign, gitsign
  for _, s in ipairs(get_signs()) do
    if s.name:find('GitSign') then
      gitsign = '%#' .. s.texthl .. '#' .. s.text .. '%*'
    else
      sign = '%#' .. s.texthl .. '#' .. s.text .. '%*'
    end
  end

  local function show_break()
    if vim.v.virtnum > 0 then
      return (' '):rep(math.floor(math.ceil(math.log10(vim.v.lnum))) - 1) .. '↳'
    elseif vim.v.virtnum < 0 then
      return ''
    else
      return vim.v.lnum
    end
  end

  return (sign and sign or fill_space(2))
    .. '%='
    .. show_break()
    .. (gitsign and gitsign or fill_space(2))
end

vim.opt_local.stc = [[%!v:lua.show_stc()]]

if vim.uv.os_uname().sysname == 'Darwin' then
  vim.g.clipboard = {
    name = 'macOS-clipboard',
    copy = {
      ['+'] = 'pbcopy',
      ['*'] = 'pbcopy',
    },
    paste = {
      ['+'] = 'pbpaste',
      ['*'] = 'pbpaste',
    },
    cache_enabled = 0,
  }
end
