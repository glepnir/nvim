local pbind = require('publibs.plbind')
local map_cr = pbind.map_cr
local map_cu = pbind.map_cu
local map_cmd = pbind.map_cmd
local map_args = pbind.map_args
local vim = vim

local mapping = setmetatable({}, { __index = { vim = {},plugin = {} } })

function _G.check_back_space()
    local col = vim.fn.col('.') - 1
    if col == 0 or vim.fn.getline('.'):sub(col, col):match('%s') then
        return true
    else
        return false
    end
end

function mapping:load_vim_define()
  self.vim= {
    -- Vim map
    ["n|<C-x>k"]     = map_cr('Bdelete'):with_noremap():with_silent(),
    ["n|<C-s>"]      = map_cu('write'):with_noremap(),
    ["n|Y"]          = map_cmd('y$'),
    ["n|]w"]         = map_cu('WhitespaceNext'):with_noremap(),
    ["n|[w"]         = map_cu('WhitespacePrev'):with_noremap(),
    ["n|]b"]         = map_cu('bp'):with_noremap(),
    ["n|[b"]         = map_cu('bn'):with_noremap(),
    ["n|<Space>cw"]  = map_cu([[silent! keeppatterns %substitute/\s\+$//e]]):with_noremap():with_silent(),
    ["n|<C-h>"]      = map_cmd('<C-w>h'):with_noremap(),
    ["n|<C-l>"]      = map_cmd('<C-w>l'):with_noremap(),
    ["n|<C-j>"]      = map_cmd('<C-w>j'):with_noremap(),
    ["n|<C-k>"]      = map_cmd('<C-w>k'):with_noremap(),
    ["n|<C-w>["]     = map_cr('vertical resize -5'),
    ["n|<C-w>]"]     = map_cr('vertical resize +5'),
    ["n|<Leader>ss"] = map_cu('SessionSave'):with_noremap(),
    ["n|<Leader>sl"] = map_cu('SessionLoad'):with_noremap(),
  -- Insert
    ["i|<C-w>"]      = map_cmd('<C-[>diwa'):with_noremap(),
    ["i|<C-h>"]      = map_cmd('<BS>'):with_noremap(),
    ["i|<C-d>"]      = map_cmd('<Del>'):with_noremap(),
    ["i|<C-k>"]      = map_cmd('<ESC>d$a'):with_noremap(),
    ["i|<C-u>"]      = map_cmd('<C-G>u<C-U>'):with_noremap(),
    ["i|<C-b>"]      = map_cmd('<Left>'):with_noremap(),
    ["i|<C-f>"]      = map_cmd('<Right>'):with_noremap(),
    ["i|<C-a>"]      = map_cmd('<ESC>^i'):with_noremap(),
    ["i|<C-o>"]      = map_cmd('<Esc>o'):with_noremap(),
    ["i|<C-s>"]      = map_cmd('<Esc>:w<CR>'),
    ["i|<C-q>"]      = map_cmd('<Esc>:wq<CR>'),
    ["i|<C-e>"]      = map_cmd([[pumvisible() ? "\<C-e>" : "\<End>"]]):with_noremap():with_expr(),
    -- TODO Wrap line
    ["i|<TAB>"]      = map_cmd([[pumvisible() ? "\<C-n>" : vsnip#available(1) ?"\<Plug>(vsnip-expand-or-jump)" : v:lua.check_back_space() ? "\<TAB>" : completion#trigger_completion()]]):with_expr():with_silent(),
    ["i|<S-TAB>"]    = map_cmd([[pumvisible() ? "\<C-p>" : "\<C-h>"]]):with_noremap():with_expr(),
    ["i|<CR>"]       = map_cmd([[pumvisible() ? complete_info()["selected"] != "-1" ?"\<Plug>(completion_confirm_completion)"  : "\<c-e>\<CR>":(delimitMate#WithinEmptyPair() ? "\<Plug>delimitMateCR" : "\<CR>")]]):with_expr(),
  -- command line
    ["c|<C-b>"]      = map_cmd('<Left>'):with_noremap(),
    ["c|<C-f>"]      = map_cmd('<Right>'):with_noremap(),
    ["c|<C-a>"]      = map_cmd('<Home>'):with_noremap(),
    ["c|<C-e>"]      = map_cmd('<End>'):with_noremap(),
    ["c|<C-d>"]      = map_cmd('<Del>'):with_noremap(),
    ["c|<C-h>"]      = map_cmd('<BS>'):with_noremap(),
    ["c|<C-t>"]      = map_cmd([[<C-R>=expand("%:p:h") . "/" <CR>]]):with_noremap(),
  }
end

function mapping:load_plugin_define()
  self.plugin = {
    ["n|gb"]             = map_cr("BufferLinePick"):with_noremap():with_silent(),
    -- Lsp mapp work when insertenter and lsp start
    ["n|[e"]             = map_cmd("<cmd>lua require'lspsaga.diagnostic'.lsp_jump_diagnostic_next()<CR>"):with_noremap():with_silent(),
    ["n|]e"]             = map_cmd("<cmd>lua require'lspsaga.diagnostic'.lsp_jump_diagnostic_prev()<CR>"):with_noremap():with_silent(),
    ["n|K"]              = map_cmd("<cmd>lua vim.lsp.buf.hover()<CR>"):with_noremap():with_silent(),
    ["n|ga"]             = map_cmd("<cmd>lua vim.lsp.buf.code_action()<CR>"):with_noremap():with_silent(),
    ["n|gd"]             = map_cmd("<cmd>lua require'lspsaga.provider'.preview_definiton()<CR>"):with_noremap():with_silent(),
    ["n|gD"]             = map_cmd("<cmd>lua vim.lsp.buf.implementation()<CR>"):with_noremap():with_silent(),
    ["n|gs"]             = map_cmd("<cmd>lua vim.lsp.buf.signature_help()<CR>"):with_noremap():with_silent(),
    ["n|gr"]             = map_cmd("<cmd>lua vim.lsp.buf.references()<CR>"):with_noremap():with_silent(),
    ["n|gh"]             = map_cmd("<cmd>lua require'lspsaga.provider'.lsp_finder({definition_icon='  ',reference_icon = '  '})<CR>"):with_noremap():with_silent(),
    ["n|gt"]             = map_cmd("<cmd>lua vim.lsp.buf.type_definition()<CR>"):with_noremap():with_silent(),
    ["n|<Leader>cw"]     = map_cmd("<cmd>lua vim.lsp.buf.workspace_symbol()<CR>"):with_noremap():with_silent(),
    ["n|<Leader>ce"]     = map_cmd("<cmd>lua require'lspsaga.diagnostic'.show_buf_diagnostics()<CR>"):with_noremap():with_silent(),
    ["n|<Leader>ct"]      = map_args("Template"),
    -- dein
    ["n|<Leader>tr"]     = map_cr("call dein#recache_runtimepath()"):with_noremap():with_silent(),
    ["n|<Leader>tf"]     = map_cu('DashboardNewFile'):with_noremap():with_silent(),
    -- mhinz/vim-signify
    ["n|[g"]             = map_cmd("<plug>(signify-next-hunk)"),
    ["n|]g"]             = map_cmd("<plug>(signify-prev-hunk)"),
    -- Plugin nvim-tree
    ["n|<Leader>e"]      = map_cr('LuaTreeToggle'):with_noremap():with_silent(),
    ["n|<Leader>F"]      = map_cr('LuaTreeFindFile'):with_noremap():with_silent(),
    -- Plugin MarkdownPreview
    ["n|<Leader>om"]     = map_cu('MarkdownPreview'):with_noremap():with_silent(),
    -- Plugin DadbodUI
    ["n|<Leader>od"]     = map_cr('DBUIToggle'):with_noremap():with_silent(),
    -- Plugin Floaterm
    ["n|<A-d>"]          = map_cu("lua require('internal.selfunc').float_terminal()"):with_noremap():with_silent(),
    ["t|<A-d>"]          = map_cu([[<C-\><C-n>:lua require('internal.selfunc').close_float_terminal()<CR>]]):with_noremap():with_silent(),
    ["n|<Leader>g"]      = map_cu("lua require('internal.selfunc').float_terminal('lazygit')"):with_noremap():with_silent(),
    -- Far.vim
    ["n|<Leader>fz"]     = map_cr('Farf'):with_noremap():with_silent();
    ["v|<Leader>fz"]     = map_cr('Farf'):with_noremap():with_silent();
    -- Plugin Clap
    ["n|<Leader>bb"]     = map_cu('Telescope buffers'):with_noremap():with_silent(),
    ["n|<Leader>fa"]     = map_cu('DashboardFindWord'):with_noremap():with_silent(),
    ["n|<Leader>fb"]     = map_cu('DashboardJumpMark'):with_noremap():with_silent(),
    ["n|<Leader>ff"]     = map_cu('DashboardFindFile'):with_noremap():with_silent(),
    ["n|<Leader>fg"]     = map_cu('Telescope git_files'):with_noremap():with_silent(),
    ["n|<Leader>fw"]     = map_cu('Telescope grep_string'):with_noremap():with_silent(),
    ["n|<Leader>fh"]     = map_cu('DashboardFindHistory'):with_noremap():with_silent(),
    ["n|<Leader>fl"]     = map_cu('Telescope loclist'):with_noremap():with_silent(),
    ["n|<Leader>fc"]     = map_cu('Telescope git_commits'):with_noremap():with_silent(),
    ["n|<Leader>fd"]     = map_cu('lua require"telescope".load_dotfiles()'):with_noremap():with_silent(),
    -- ["n|<Leader>fs"]      = map_cu('Clap gosource'):with_noremap():with_silent(),
    -- Plugin acceleratedjk
    ["n|j"]              = map_cmd('<Plug>(accelerated_jk_gj)'):with_silent(),
    ["n|k"]              = map_cmd('<Plug>(accelerated_jk_gk)'):with_silent(),
    -- Plugin QuickRun
    ["n|<Leader>r"]     = map_cr("<cmd> lua require'internal.selfunc'.run_command()"):with_noremap():with_silent(),
    -- Plugin Vista
    ["n|<Leader>v"]      = map_cu('Vista!!'):with_noremap():with_silent(),
    -- Plugin vim-operator-replace
    ["x|p"]              = map_cmd("<Plug>(operator-replace)"),
    -- Plugin vim-operator-surround
    ["n|sa"]             = map_cmd("<Plug>(operator-surround-append)"):with_silent(),
    ["n|sd"]             = map_cmd("<Plug>(operator-surround-delete)"):with_silent(),
    ["n|sr"]             = map_cmd("<Plug>(operator-surround-replace)"):with_silent(),
    -- Plugin hrsh7th/vim-eft
    ["n|;"]              = map_cmd("<Plug>(eft-repeat)"),
    ["x|;"]              = map_cmd("<Plug>(eft-fepeat)"),
    ["n|f"]              = map_cmd("<Plug>(eft-f)"),
    ["x|f"]              = map_cmd("<Plug>(eft-f)"),
    ["o|f"]              = map_cmd("<Plug>(eft-f)"),
    ["n|F"]              = map_cmd("<Plug>(eft-F)"),
    ["x|F"]              = map_cmd("<Plug>(eft-F)"),
    ["o|F"]              = map_cmd("<Plug>(eft-F)"),
  };
end

local function load_mapping()
  mapping:load_vim_define()
  mapping:load_plugin_define()
  pbind.nvim_load_mapping(mapping.vim)
  pbind.nvim_load_mapping(mapping.plugin)
end

load_mapping()
