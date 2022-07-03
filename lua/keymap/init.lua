require('keymap.remap')
local keymap = require('core.keymap')
local map = keymap.map
local silent,noremap,expr,remap =keymap.silent,keymap.noremap,keymap.expr,keymap.remap
local opts = keymap.new_opts
local cmd,cu = keymap.cmd,keymap.cu
local home = os.getenv('HOME')
require('keymap.config')

map {
  -- tab key
  {'i','<TAB>',_G.smart_tab,opts(expr,silent,remap)},
  {'i','<S-TAB>',_G.smart_shift_tab,opts(expr,silent,remap)},

  -- packer
  {'n','<Leader>pu',cmd('PackerUpdate'),opts(noremap,silent)},
  {'n','<Leader>pi',cmd('PackerInstall'),opts(noremap,silent)},
  {'n','<Leader>pc',cmd('PackerCompile'),opts(noremap,silent)},
  -- Lsp
  {'n','<Leader>li',cmd('LspInfo'),opts(noremap,silent)},
  {'n','<Leader>ll',cmd('LspLog'),opts(noremap,silent)},
  {'n','<Leader>lr',cmd('LspRestart'),opts(noremap,silent)},
  {'n','<C-f>',cmd("lua require('lspsaga.action').smart_scroll_with_saga(1)"),opts(noremap,silent)},
  {'n','<C-b>',cmd("lua require('lspsaga.action').smart_scroll_with_saga(-1)"),opts(noremap,silent)},
  -- Lspsaga
  {'n','[e',cmd('Lspsaga diagnostic_jump_next'),opts(noremap,silent)},
  {'n',']e',cmd('Lspsaga diagnostic_jump_prev'),opts(noremap,silent)},
  {'n','K',cmd('Lspsaga hover_doc'),opts(noremap,silent)},
  {'n','ga',cmd('Lspsaga code_action'),opts(noremap,silent)},
  {'v','ga',cu('Lspsaga code_action'),opts(noremap,silent)},
  {'n','gd',cmd('Lspsaga range_code_action'),opts(noremap,silent)},
  {'n','gs',cmd('Lspsaga signature_hel'),opts(noremap,silent)},
  {'n','gr',cmd('Lspsaga rename'),opts(noremap,silent)},
  {'n','gh',cmd('Lspsaga lsp_finder'),opts(noremap,silent)},
  -- Lspsaga floaterminal
  {'n','<A-d>',cmd('Lspsaga open_floaterm'),opts(noremap,silent)},
  {'n','<Leader>g',cmd('Lspsaga open_floaterm lazygit'),opts(noremap,silent)},
  {'t','<A-d>',[[<C-\><C-n>:Lspsaga close_floaterm<CR>]],opts(noremap,silent)},
  -- dashboard create file
  {'n','<Leader>n',cmd('DashboardNewFile'),opts(noremap,silent)},
  {'n','<Leader>ss',cmd('SessionSave'),opts(noremap,silent)},
  {'n','<Leader>sl',cmd('SessionLoad'),opts(noremap,silent)},
  -- nvimtree
  {'n','<Leader>e',cmd('NvimTreeToggle'),opts(noremap,silent)},
  -- dadbodui
  {'n','<Leader>od',cmd('DBUIToggle'),opts(noremap,silent)},
  -- Telescope
  {'n','<Leader>b',cmd('Telescope buffers'),opts(noremap,silent)},
  {'n','<Leader>fa',cmd('Telescope live_grep'),opts(noremap,silent)},
  {'n','<Leader>fb',cmd('Telescope file_browser'),opts(noremap,silent)},
  {'n','<Leader>ff',cmd('Telescope find_files'),opts(noremap,silent)},
  {'n','<Leader>fg',cmd('Telescope gif_files'),opts(noremap,silent)},
  {'n','<Leader>fw',cmd('Telescope grep_string'),opts(noremap,silent)},
  {'n','<Leader>fh',cmd('Telescope oldfiles'),opts(noremap,silent)},
  {'n','<Leader>gc',cmd('Telescope git_commits'),opts(noremap,silent)},
  {'n','<Leader>gc',cmd('Telescope dotfiles path'..home ..'/.dotfiles'),opts(noremap,silent)},
  -- prodoc
  {'n','gcc',cmd('ProComment'),opts(noremap,silent)},
  {'x','gcc',cu('ProComment'),opts(noremap,silent)},
  {'n','gcj',cmd('ProDoc'),opts(noremap,silent)},
  -- vista
  {'n','<Leader>v',cmd('Vista'),opts(noremap,silent)},
  -- vim-operator-surround
  {'n','sa','<Plug>(operator-surround-append)',opts(noremap,silent)},
  {'n','sd','<Plug>(operator-surround-delete)',opts(noremap,silent)},
  {'n','sr','<Plug>(operator-surround-replace)',opts(noremap,silent)},
  -- nice_block
  {'x','I',_G.enhance_nice_block('I'),opts(expr)},
  {'x','gI',_G.enhance_nice_block('gI'),opts(expr)},
  {'x','A',_G.enhance_nice_block('A'),opts(expr)},

}
