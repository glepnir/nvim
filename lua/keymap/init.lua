require('keymap.remap')
local keymap = require('core.keymap')
local nmap, imap, xmap, tmap = keymap.nmap, keymap.imap, keymap.xmap, keymap.tmap
local expr, remap = keymap.expr, keymap.remap
local opts = keymap.new_opts
local cmd = keymap.cmd
local home = os.getenv('HOME')
require('keymap.config')

imap({
  -- tab key
  { '<TAB>', _G.smart_tab, opts(expr, remap) },
  { '<S-TAB>', _G.smart_shift_tab, opts(expr, remap) },
})

nmap({
  -- packer
  { '<Leader>pu', cmd('PackerUpdate') },
  { '<Leader>pi', cmd('PackerInstall') },
  { '<Leader>pc', cmd('PackerCompile') },
  -- Lsp
  { '<Leader>li', cmd('LspInfo') },
  { '<Leader>ll', cmd('LspLog') },
  { '<Leader>lr', cmd('LspRestart') },
  -- Lspsaga
  { '[e', cmd('Lspsaga diagnostic_jump_next') },
  { ']e', cmd('Lspsaga diagnostic_jump_prev') },
  { 'K', cmd('Lspsaga hover_doc') },
  { 'ga', cmd('Lspsaga code_action') },
  { 'gd', cmd('Lspsaga peek_definition') },
  { 'gs', cmd('Lspsaga signature_help') },
  { 'gr', cmd('Lspsaga rename') },
  { 'gh', cmd('Lspsaga lsp_finder') },
  { '<Leader>o', cmd('LSoutlineToggle') },
  { '<Leader>g', cmd('Lspsaga open_floaterm lazygit') },
  -- dashboard create file
  { '<Leader>n', cmd('DashboardNewFile') },
  { '<Leader>ss', cmd('SessionSave') },
  { '<Leader>sl', cmd('SessionLoad') },
  -- nvimtree
  { '<Leader>e', cmd('NvimTreeToggle') },
  -- dadbodui
  { '<Leader>d', cmd('DBUIToggle') },
  -- Telescope
  { '<Leader>b', cmd('Telescope buffers') },
  { '<Leader>fa', cmd('Telescope live_grep') },
  { '<Leader>fl', cmd('Telescope file_browser') },
  { '<Leader>fd', cmd('Telescope dotfiles') },
  { '<Leader>ff', cmd('Telescope find_files') },
  { '<Leader>fg', cmd('Telescope gif_files') },
  { '<Leader>fw', cmd('Telescope grep_string') },
  { '<Leader>fh', cmd('Telescope help_tags') },
  { '<Leader>fo', cmd('Telescope oldfiles') },
  { '<Leader>gc', cmd('Telescope git_commits') },
  { '<Leader>gc', cmd('Telescope dotfiles path' .. home .. '/.dotfiles') },
  -- vim-operator-surround
  { 'sa', '<Plug>(operator-surround-append)' },
  { 'sd', '<Plug>(operator-surround-delete)' },
  { 'sr', '<Plug>(operator-surround-replace)' },
  -- hop.nvim
  { 'f', cmd('HopWordAC') },
  { 'F', cmd('HopWordBC') },
})
nmap({ 'gcc', cmd('ComComment') })
xmap({ 'gcc', ':ComComment<CR>' })
nmap({ 'gcj', cmd('ComAnnotation') })

-- Lspsaga floaterminal
nmap({ '<A-d>', cmd('Lspsaga open_floaterm') })
tmap({ '<A-d>', [[<C-\><C-n>:Lspsaga close_floaterm<CR>]] })

xmap({ 'ga', cmd('Lspsaga code_action') })
