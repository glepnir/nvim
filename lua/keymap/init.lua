local api = vim.api
require('keymap.remap')
local keymap = require('core.keymap')
local nmap, imap, xmap, tmap = keymap.nmap, keymap.imap, keymap.xmap, keymap.tmap
local expr, remap = keymap.expr, keymap.remap
local opts = keymap.new_opts
local cmd = keymap.cmd
require('keymap.config')

imap({
  -- tab key
  { '<TAB>', _G.smart_tab, opts(expr, remap) },
  { '<S-TAB>', _G.smart_shift_tab, opts(expr, remap) },
})

nmap({
  -- packer
  { '<Leader>pu', cmd('Lazy update') },
  { '<Leader>pi', cmd('Lazy install') },
  -- Lsp
  { '<Leader>li', cmd('LspInfo') },
  { '<Leader>ll', cmd('LspLog') },
  { '<Leader>lr', cmd('LspRestart') },
  -- Lspsaga
  { '[e', cmd('Lspsaga diagnostic_jump_next') },
  { ']e', cmd('Lspsaga diagnostic_jump_prev') },
  { '[c', cmd('Lspsaga show_cursor_diagnostics') },
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
  -- dadbodui
  { '<Leader>d', cmd('DBUIToggle') },
  -- Telescope
  { '<Leader>a', cmd('Telescope app') },
  { '<Leader>j', cmd('Telescope buffers') },
  { '<Leader>fa', cmd('Telescope live_grep') },
  { '<Leader>fs', cmd('Telescope grep_string') },
  {
    '<Leader>e',
    function()
      vim.cmd('Telescope file_browser')
      local esc_key = api.nvim_replace_termcodes('<Esc>', true, false, true)
      api.nvim_feedkeys(esc_key, 'n', false)
    end,
  },
  { '<Leader>ff', cmd('Telescope find_files find_command=rg,--ignore,--hidden,--files') },
  { '<Leader>fg', cmd('Telescope git_files') },
  { '<Leader>fw', cmd('Telescope grep_string') },
  { '<Leader>fh', cmd('Telescope help_tags') },
  { '<Leader>fo', cmd('Telescope oldfiles') },
  { '<Leader>gc', cmd('Telescope git_commits') },
  { '<Leader>fd', cmd('Telescope dotfiles') },
  -- hop.nvim
  { 'f', cmd('HopWordAC') },
  { 'F', cmd('HopWordBC') },
  -- template.nvim
  {
    '<Leader>t',
    function()
      if vim.bo.filetype == 'lua' then
        return ':Template var='
      end

      if vim.bo.filetype == 'rust' then
        return '<Cmd>Template main_owner<CR>'
      end

      local buf_name = api.nvim_buf_get_name(0)
      if vim.bo.filetype == 'go' and buf_name:find('main.go') then
        return '<Cmd>Template main_owner<CR>'
      end
      return ':Template '
    end,
    opts(expr),
  },
})

nmap({ 'gcc', cmd('ComComment') })
xmap({ 'gcc', ':ComComment<CR>' })
nmap({ 'gcj', cmd('ComAnnotation') })

-- Lspsaga floaterminal
nmap({ '<A-d>', cmd('Lspsaga open_floaterm') })
tmap({ '<A-d>', [[<C-\><C-n>:Lspsaga close_floaterm<CR>]] })

xmap({ 'ga', cmd('Lspsaga code_action') })
