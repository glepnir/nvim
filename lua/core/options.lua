local api = vim.api
local opt = vim.opt

opt.hidden = true
opt.magic = true
opt.virtualedit = 'block'
opt.clipboard = 'unnamedplus'
opt.wildignorecase = true
opt.swapfile = false

opt.history = 1000
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

opt.completeopt = 'menu,menuone,noinsert'
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

--eol:¬
opt.listchars = 'tab:» ,nbsp:+,trail:·,extends:→,precedes:←,'
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
opt.signcolumn = 'no'
opt.spelloptions = 'camel'

opt.textwidth = 80
opt.colorcolumn = '+0'

local function get_signs(name)
  return function()
    local bufnr = vim.api.nvim_win_get_buf(vim.g.statusline_winid)
    local it = vim
      .iter(api.nvim_buf_get_extmarks(bufnr, -1, 0, -1, { details = true, type = 'sign' }))
      :find(function(item)
        return item[2] == vim.v.lnum - 1
          and item[4].sign_hl_group
          and item[4].sign_hl_group:find(name)
      end)
    return not it and '  ' or ('%%#%s#%s%%*'):format(it[4].sign_hl_group, it[4].sign_text)
  end
end

function _G.show_stc()
  local stc_diagnostic = get_signs('Diagnostic')
  local stc_gitsign = get_signs('GitSign')

  local function show_break()
    if vim.v.virtnum > 0 then
      return (' '):rep(math.floor(math.ceil(math.log10(vim.v.lnum))) - 1) .. '↳'
    elseif vim.v.virtnum < 0 then
      return ''
    else
      return vim.v.lnum
    end
  end
  return ('%s%%=%s%s'):format(stc_diagnostic(), show_break(), stc_gitsign())
end

vim.opt.stc = '%!v:lua.show_stc()'

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
