require('keymap.remap')
local map = require('core.keymap')
local cmd = map.cmd

map.n({
  -- Lspsaga
  ['[d'] = ':Lspsaga diagnostic_jump_next<CR>',
  [']d'] = ':Lspsaga diagnostic_jump_prev<CR>',
  ['K'] = cmd('Lspsaga hover_doc'),
  ['ga'] = cmd('Lspsaga code_action'),
  ['gr'] = cmd('Lspsaga rename'),
  ['gd'] = cmd('Lspsaga peek_definition'),
  ['gp'] = cmd('Lspsaga goto_definition'),
  ['gh'] = cmd('Lspsaga finder'),
  ['<Leader>o'] = cmd('Lspsaga outline'),
  ['<Leader>dw'] = cmd('Lspsaga show_workspace_diagnostics'),
  ['<Leader>db'] = cmd('Lspsaga show_buf_diagnostics'),
  -- dbsession
  ['<Leader>ss'] = cmd('SessionSave'),
  ['<Leader>sl'] = cmd('SessionLoad'),
  -- Telescope
  ['<Leader>a'] = cmd('Telescope app'),
  ['<Leader>fa'] = cmd('Telescope live_grep'),
  ['<Leader>fs'] = cmd('Telescope grep_string'),
  ['<Leader>ff'] = cmd('Telescope find_files find_command=rg,--ignore,--hidden,--files'),
  ['<Leader>fg'] = cmd('Telescope git_files'),
  -- find in workspace folder which is my project directory
  ['<Leader>fw'] = cmd(
    'Telescope find_files cwd=$HOME/workspace' .. ' find_command=rg,--ignore,--hidden,--files'
  ),
  ['<Leader>fh'] = cmd('Telescope help_tags'),
  ['<Leader>fo'] = cmd('Telescope oldfiles'),
  ['<Leader>gc'] = cmd('Telescope git_commits'),
  ['<Leader>fd'] = cmd('Telescope dotfiles'),
  -- flybuf.nvim
  ['<Leader>j'] = cmd('FlyBuf'),
  --gitsign
  [']g'] = cmd('lua require"gitsigns".next_hunk()<CR>'),
  ['[g'] = cmd('lua require"gitsigns".prev_hunk()<CR>'),
  --rapid
  ['<leader>c'] = cmd('Rapid'),
})

--template.nvim
map.n('<Leader>t', function()
  local tmp_name
  if vim.bo.filetype == 'lua' then
    tmp_name = 'nvim_temp'
  end
  if tmp_name then
    vim.cmd('Template ' .. tmp_name)
    return
  end
  return ':Template '
end, { expr = true })

-- Lspsaga floaterminal
map.nt('<A-d>', cmd('Lspsaga term_toggle'))

map.nx('ga', cmd('Lspsaga code_action'))

local loaded_netrw = false
map.n('<leader>n', function()
  if not loaded_netrw then
    vim.g.loaded_netrwPlugin = nil
    vim.g.netrw_keepdir = 0
    vim.g.netrw_winsize = math.floor((30 / vim.o.columns) * 100)
    vim.g.netrw_banner = 0
    vim.g.netrw_list_hide = [[\(^\|\s\s\)\zs\.\S\+]]
    vim.g.netrw_liststyle = 3
    vim.cmd.source(vim.env.VIMRUNTIME .. '/plugin/netrwPlugin.vim')
    vim.cmd('Lexplore %:p:h')
    loaded_netrw = true
    return
  end
  vim.cmd('Lexplore %:p:h')
end)
