require('keymap.remap')
local map = require('core.keymap')
local cmd = map.cmd

map.n({
  -- Lspsaga
  ['[d'] = cmd('Lspsaga diagnostic_jump_next'),
  [']d'] = cmd('Lspsaga diagnostic_jump_prev'),
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
  -- FzfLua
  ['<Leader>b'] = cmd('FzfLua buffers'),
  ['<Leader>fa'] = cmd('FzfLua live_grep_native'),
  ['<Leader>fs'] = cmd('FzfLua grep_cword'),
  ['<Leader>ff'] = cmd('FzfLua files'),
  ['<Leader>fh'] = cmd('FzfLua helptags'),
  ['<Leader>fo'] = cmd('FzfLua oldfiles'),
  ['<Leader>fg'] = cmd('FzfLua git_files'),
  ['<Leader>gc'] = cmd('FzfLua git_commits'),
  ['<Leader>fc'] = cmd('FzfLua files cwd=$HOME/.config'),
  -- flybuf.nvim
  ['<Leader>j'] = cmd('FlyBuf'),
  --gitsign
  [']g'] = cmd('lua require"gitsigns".next_hunk()<CR>'),
  ['[g'] = cmd('lua require"gitsigns".prev_hunk()<CR>'),
})

vim.keymap.set({ 'n' }, '<C-x><C-f>', function()
  require('fzf-lua').complete_file({
    cmd = 'rg --files',
    winopts = { preview = { hidden = 'nohidden' } },
  })
end, { silent = true, desc = 'Fuzzy complete file' })

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
-- keymap see internal/event.lua
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
