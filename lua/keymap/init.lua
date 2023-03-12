local api = vim.api
require('keymap.remap')
local map = require('core.keymap')
local cmd = map.cmd

map.n({
  ['<Leader>pu'] = cmd('Lazy update'),
  ['<Leader>pi'] = cmd('Lazy install'),
  -- Lsp
  ['<Leader>li'] = cmd('LspInfo'),
  ['<Leader>ll'] = cmd('LspLog'),
  ['<Leader>lr'] = cmd('LspRestart'),
  -- Lspsaga
  ['[e'] = cmd('Lspsaga diagnostic_jump_next'),
  [']e'] = cmd('Lspsaga diagnostic_jump_prev'),
  ['[c'] = cmd('Lspsaga show_cursor_diagnostics'),
  ['K'] = cmd('Lspsaga hover_doc'),
  ['ga'] = cmd('Lspsaga code_action'),
  ['gd'] = cmd('Lspsaga peek_definition'),
  ['gD'] = cmd('Lspsaga goto_definition'),
  ['gr'] = cmd('Lspsaga rename'),
  ['gh'] = cmd('Lspsaga lsp_finder'),
  ['<Leader>o'] = cmd('Lspsaga outline'),
  -- dbsession
  ['<Leader>ss'] = cmd('SessionSave'),
  ['<Leader>sl'] = cmd('SessionLoad'),
  -- Telescope
  ['<Leader>a'] = cmd('Telescope app'),
  ['<Leader>fa'] = cmd('Telescope live_grep'),
  ['<Leader>fs'] = cmd('Telescope grep_string'),
  ['<Leader>ff'] = cmd('Telescope find_files find_command=rg,--ignore,--hidden,--files'),
  ['<Leader>fg'] = cmd('Telescope git_files'),
  ['<Leader>fw'] = cmd('Telescope grep_string'),
  ['<Leader>fh'] = cmd('Telescope help_tags'),
  ['<Leader>fo'] = cmd('Telescope oldfiles'),
  ['<Leader>gc'] = cmd('Telescope git_commits'),
  ['<Leader>fd'] = cmd('Telescope dotfiles'),
  -- hop.nvim
  ['f'] = cmd('HopWordAC'),
  ['F'] = cmd('HopWordBC'),
  -- flybuf.nvim
  ['<Leader>j'] = cmd('FlyBuf'),
})

map.n('<Leader>e', function()
  vim.cmd('Telescope file_browser')
  local esc_key = api.nvim_replace_termcodes('<Esc>', true, false, true)
  api.nvim_feedkeys(esc_key, 'n', false)
end)

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

map.n('gcc', cmd('ComComment'))
map.x('gcc', ':ComComment<CR>')
map.n('gcj', cmd('ComAnnotation'))

-- Lspsaga floaterminal
map.nt('<A-d>', cmd('Lspsaga term_toggle'))

map.nx('ga', cmd('Lspsaga code_action'))
