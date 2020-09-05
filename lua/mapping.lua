require 'global'

mapping = {}
rhs_options = {}

function mapping:new()
  instance = {}
  setmetatable(instance, self)
  self.__index = self
  return instance
end

function mapping:load_vim_define()
  self.vim= {
    -- Vim map
    ["n|<C-x>k"]     = map_cr('Bdelete'):with_noremap(),
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
    ["i|<TAB>"]      = map_cmd([[pumvisible() ? "\<C-n>" : vsnip#available(1) ?"\<Plug>(vsnip-expand-or-jump)" : initself#check_back_space() ? "\<TAB>" : completion#trigger_completion()]]):with_expr():with_silent(),
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
    -- Lsp
    ["n|K"]              = map_cmd("<cmd>lua vim.lsp.buf.hover()<CR>"):with_noremap():with_silent(),
    ["n|gd"]             = map_cr("call initself#definition_other_window()"):with_noremap():with_silent(),
    ["n|gD"]             = map_cmd("<cmd>lua vim.lsp.buf.implementation()<CR>"):with_noremap():with_silent(),
    ["n|gk"]             = map_cmd("<cmd>lua vim.lsp.buf.signature_help()<CR>"):with_noremap():with_silent(),
    ["n|gr"]             = map_cmd("<cmd>lua vim.lsp.buf.references()<CR>"):with_noremap():with_silent(),
    ["n|<Leader>cw"]     = map_cmd("<cmd>lua vim.lsp.buf.workspace_symbol()<CR>"):with_noremap():with_silent(),
    -- dein
    ["n|<LocalLeader>r"] = map_cr("call dein#recache_runtimepath()"):with_noremap():with_silent(),
    ["n|<LocalLeader>u"] = map_cr("call dein#update()"):with_noremap():with_silent(),
    ["n|<Leader>tf"]     = map_cu('DashboardNewFile'):with_noremap():with_silent(),
    ["n|<Leader>bc"]     = map_cr('Bonly'):with_noremap():with_silent(),
    ["n|<Leader>bx"]     = map_cr('Bw'):with_noremap():with_silent(),
    ["n|<Leader>,0,9"]   = "<Plug>BuffetSwitch(+)",
    -- Plugin Defx
    ["n|<Leader>e"]      = map_cu([[Defx -resume -toggle -buffer-name=tab`tabpagenr()`]]):with_noremap():with_silent(),
    ["n|<Leader>F"]      = map_cu([[Defx -resume -buffer-name=tab`tabpagenr()` -search=`expand('%:p')`]]):with_noremap():with_silent(),
    -- Plugin MarkdownPreview
    ["n|<Leader>om"]     = map_cu('MarkdownPreview'):with_noremap():with_silent(),
    -- Plugin DadbodUI
    ["n|<Leader>od"]     = map_cr('DBUIToggle'):with_noremap():with_silent(),
    -- Plugin Floaterm
    ["n|<Leader>t"]      = map_cu('FloatermToggle'):with_noremap():with_silent(),
    ["n|<Leader>g"]      = map_cu('FloatermNew height=0.7 width=0.8 lazygit'):with_noremap():with_silent(),
    -- Plugin Clap
    ["n|<Leader>tc"]     = map_cu('Clap colors'):with_noremap():with_silent(),
    ["n|<Leader>bb"]     = map_cu('Clap bufers'):with_noremap():with_silent(),
    ["n|<Leader>fa"]     = map_cu('Clap grep'):with_noremap():with_silent(),
    ["n|<Leader>fb"]     = map_cu('Clap marks'):with_noremap():with_silent(),
    ["n|<C-x><C-f>"]     = map_cu('Clap filer'):with_noremap():with_silent(),
    ["n|<Leader>ff"]     = map_cu('Clap files ++finder=rg --ignore --hidden --files'):with_noremap():with_silent(),
    ["n|<Leader>fg"]     = map_cu('Clap gfiles'):with_noremap():with_silent(),
    ["n|<Leader>fw"]     = map_cu('Clap grep ++query=<Cword>'):with_noremap():with_silent(),
    ["n|<Leader>fh"]     = map_cu('Clap history'):with_noremap():with_silent(),
    ["n|<Leader>fW"]     = map_cu('Clap windows'):with_noremap():with_silent(),
    ["n|<Leader>fl"]     = map_cu('Clap loclist'):with_noremap():with_silent(),
    ["n|<Leader>fu"]     = map_cu('Clap git_diff_files'):with_noremap():with_silent(),
    ["n|<Leader>fv"]     = map_cu('Clap grep ++query=@visual'):with_noremap():with_silent(),
    ["n|<Leader>oc"]     = map_cu('Clap dotfiles'):with_noremap():with_silent(),
    ["n|<LocalLeader>g"] = map_cu('Clap gosource'):with_noremap():with_silent(),
    -- Plugin acceleratedjk
    ["n|j"]              = map_cmd('<Plug>(accelerated_jk_gj)'),
    ["n|k"]              = map_cmd('<Plug>(accelerated_jk_gk)'),
    -- Plugin QuickRun
    ["n|<Leader>cr"]     = map_cr('QuickRun'):with_noremap():with_silent(),
    -- Plugin Vista
    ["n|<Leader>i"]      = map_cu('Vista!!'):with_noremap():with_silent(),
    -- Plugin Easymotion
    ["n|gsj"]            = map_cmd('<Plug>(easymotion-w)'),
    ["n|gsk"]            = map_cmd('<Plug>(easymotion-b)'),
    ["n|gsf"]            = map_cmd('<Plug>(easymotion-overwin-f)'),
    ["n|gss"]            = map_cmd('<Plug>(easymotion-overwin-f2)'),
    -- Plugin Mundo
    ["n|<Leader>m"]      = map_cu('MundoToggle'):with_noremap():with_silent(),
    -- Plugin SplitJoin
    ["n|sj"]             = map_cr('SplitjoinJoin'),
    ["n|sk"]             = map_cr('SplitjoinSplit'),
    -- Plugin dsf
    ["n|dsf"]            = map_cmd('<Plug>DsfDelete'),
    ["n|csf"]            = map_cmd('<Plug>DsfChange'),
    -- Plugin go-nvim
    ["n|gcg"]            = map_cr('GoAutoComment'):with_noremap():with_silent(),
    -- Plugin vim-textobj-function
    ["o|af"]             = map_cmd("<Plug>(textobj-function-a)"):with_silent(),
    ["o|if"]             = map_cmd("<Plug>(textobj-function-i)"):with_silent(),
    ["x|af"]             = map_cmd("<Plug>(textobj-function-a)"):with_silent(),
    ["x|if"]             = map_cmd("<Plug>(textobj-function-i)"):with_silent(),
    ["x|p"]              = map_cmd("<Plug>(operator-replace)"),
    -- Plugin sandwich
    ["n|sa"]             = map_cmd("<Plug>(operator-sandwich-add)"):with_silent(),
    ["x|sa"]             = map_cmd("<Plug>(operator-sandwich-add)"):with_silent(),
    ["o|sa"]             = map_cmd("<Plug>(operator-sandwich-g@)"):with_silent(),
    ["n|sd"]             = map_cmd("<Plug>(operator-sandwich-delete)<Plug>(operator-sandwich-release-count)<Plug>(textobj-sandwich-query-a)"):with_silent(),
    ["x|sd"]             = map_cmd("<Plug>(operator-sandwich-delete)"):with_silent(),
    ["n|sr"]             = map_cmd("<Plug>(operator-sandwich-replace)<Plug>(operator-sandwich-release-count)<Plug>(textobj-sandwich-query-a)"):with_silent(),
    ["x|sr"]             = map_cmd("<Plug>(operator-sandwich-replace)"):with_silent(),
    ["n|sdb"]            = map_cmd("<Plug>(operator-sandwich-delete)<Plug>(operator-sandwich-release-count)<Plug>(textobj-sandwich-auto-a)"):with_silent(),
    ["n|srb"]            = map_cmd("<Plug>(operator-sandwich-replace)<Plug>(operator-sandwich-release-count)<Plug>(textobj-sandwich-auto-a)"):with_silent(),
    ["o|ib"]             = map_cmd("<Plug>(textobj-sandwich-auto-i)"),
    ["x|ib"]             = map_cmd("<Plug>(textobj-sandwich-auto-i)"),
    ["o|ab"]             = map_cmd("<Plug>(textobj-sandwich-auto-a)"),
    ["x|ab"]             = map_cmd("<Plug>(textobj-sandwich-auto-a)"),
    ["o|is"]             = map_cmd("<Plug>(textobj-sandwich-query-i)"),
    ["x|is"]             = map_cmd("<Plug>(textobj-sandwich-query-i)"),
    ["o|as"]             = map_cmd("<Plug>(textobj-sandwich-query-a)"),
    ["x|as"]             = map_cmd("<Plug>(textobj-sandwich-query-a)"),
  };
end


function nvim_load_mapping(mapping)
  for k,v in pairs(mapping) do
    for key,value in pairs(v) do
      local mode,keymap = key:match("([^|]*)|?(.*)")
      if type(value) == 'table' then
        rhs = value.cmd
        options = value.options
        vim.fn.nvim_set_keymap(mode,keymap,rhs,options)
      elseif type(value) == 'string' then
        local k,min,max = keymap:match("([^,]+),([^,]+),([^,]+)")
        for i=tonumber(min),tonumber(max) do
          key = (k.."%s"):format(i)
          rhs = value:gsub("+",i)
          vim.fn.nvim_set_keymap(mode,key,rhs,{})
        end
      end
    end
  end
end

function rhs_options:new()
  instance = {
    cmd = '',
    options = {
      noremap = false,
      silent = false,
      expr = false,
    }
  }
  setmetatable(instance,self)
  self.__index = self
  return instance
end

function rhs_options:map_cmd(cmd_string)
  self.cmd = cmd_string
  return self
end

function rhs_options:map_cr(cmd_string)
  self.cmd = (":%s<CR>"):format(cmd_string)
  return self
end

function rhs_options:map_cu(cmd_string)
  self.cmd = (":<C-u>%s<CR>"):format(cmd_string)
  return self
end

function rhs_options:with_silent()
  self.options.silent = true
  return self
end

function rhs_options:with_noremap()
  self.options.noremap = true
  return self
end

function rhs_options:with_expr()
  self.options.expr = true
  return self
end

function map_cr(cmd_string)
  local ro = rhs_options:new()
  return ro:map_cr(cmd_string)
end

function map_cmd(cmd_string)
  local ro = rhs_options:new()
  return ro:map_cmd(cmd_string)
end

function map_cu(cmd_string)
  local ro = rhs_options:new()
  return ro:map_cu(cmd_string)
end
