require 'global'

mapping = {}
rhs_options = {}

function mapping:new()
  instance = {}
  setmetatable(instance, self)
  self.__index = self
  self.vim    = {}
  self.plugin = {}
  return instance
end

function mapping:load_vim_define()
  ro = rhs_options:new()
  self.vim= {
    -- Vim map
    ["n|<C-x>k"]     = ro:map_cr('BD'):with_noremap(),
    ["n|<C-s>"]      = ro:map_cu('write'):with_noremap(),
    ["n|Y"]          = ro:map_cmd('y$'),
    ["n|]w"]         = ro:map_cu('WhitespaceNext'):with_noremap(),
    ["n|[w"]         = ro:map_cu('WhitespacePrev'):with_noremap(),
    ["n|]b"]         = ro:map_cu('bp'):with_noremap(),
    ["n|[b"]         = ro:map_cu('bn'):with_noremap(),
    ["n|<Space>cw"]  = ro:map_cu([[silent! keeppatterns %substitute/\s\+$//e]]):with_noremap():with_silent(),
    ["n|<C-h>"]      = ro:map_cmd('<C-w>h'):with_noremap(),
    ["n|<C-l>"]      = ro:map_cmd('<C-w>l'):with_noremap(),
    ["n|<C-j>"]      = ro:map_cmd('<C-w>j'):with_noremap(),
    ["n|<C-k>"]      = ro:map_cmd('<C-w>k'):with_noremap(),
    ["n|<C-w>["]     = ro:map_cr('vertical resize -3'),
    ["n|<C-w>]"]     = ro:map_cr('vertical resize +3'),
    ["n|<Leader>ss"] = ro:map_cu('SessionSave'):with_noremap(),
    ["n|<Leader>sl"] = ro:map_cu('SessionLoad'):with_noremap(),
  -- Insert
    ["i|<C-w>"]      = ro:map_cmd('<C-[>diwa'):with_noremap(),
    ["i|<C-h>"]      = ro:map_cmd('<BS>'):with_noremap(),
    ["i|<C-d>"]      = ro:map_cmd('<Del>'):with_noremap(),
    ["i|<C-k>"]      = ro:map_cmd('<ESC>d$a'):with_noremap(),
    ["i|<C-u>"]      = ro:map_cmd('<C-G>u<C-U>'):with_noremap(),
    ["i|<C-b>"]      = ro:map_cmd('<Left>'):with_noremap(),
    ["i|<C-f>"]      = ro:map_cmd('<Right>'):with_noremap(),
    ["i|<C-a>"]      = ro:map_cmd('<ESC>^i'):with_noremap(),
    ["i|<C-o>"]      = ro:map_cmd('<Esc>o'):with_noremap(),
    ["i|<C-s>"]      = ro:map_cmd('<Esc>:w<CR>'),
    ["i|<C-q>"]      = ro:map_cmd('<Esc>:wq<CR>'),
    ["i|<C-e>"]      = ro:map_cmd([[pumvisible() ? "\<C-e>" : "\<End>"]]):with_expr(),
  -- command line
    ["c|<C-b>"]      = ro:map_cmd('<Left>'):with_noremap(),
    ["c|<C-f>"]      = ro:map_cmd('<Right>'):with_noremap(),
    ["c|<C-a>"]      = ro:map_cmd('<Home>'):with_noremap(),
    ["c|<C-e>"]      = ro:map_cmd('<End>'):with_noremap(),
    ["c|<C-d>"]      = ro:map_cmd('<Del>'):with_noremap(),
    ["c|<C-h>"]      = ro:map_cmd('<BS>'):with_noremap(),
    ["c|<C-t>"]      = ro:map_cmd([[<C-R>=expand("%:p:h") . "/" <CR>]]):with_noremap(),
  };
end

function mapping:load_plugin_define()
  ro = rhs_options:new()
  self.plugin = {
    ["n|<Leader>tf"]     = ro:map_cu('DashboardNewFile'):with_noremap():with_silent(),
    ["n|<Leader>bc"]     = ro:map_cr('Bonly'):with_noremap():with_silent(),
    ["n|<Leader>bx"]     = ro:map_cr('Bw'):with_noremap():with_silent(),
    ["n|<Leader>,0,9"]   = '<Plug>BuffetSwitch(+)',
    -- Plugin Coc
    ["x|<Leader>a"]      = ro:map_cu("execute 'CocCommand actions.open ' . visualmode()"):with_silent(),
    ["n|<Leader>a"]      = ro:map_cmd(":<C-u>set operatorfunc=initself#coc_action_select<CR>g@"):with_silent(),
    ["n|]e"]             = ro:map_cmd('<Plug>(coc-diagnostic-prev)'):with_silent(),
    ["n|[e"]             = ro:map_cmd('<Plug>(coc-diagnostic-next)'):with_silent(),
    ["n|<Leader>cr"]     = ro:map_cmd('<Plug>(coc-rename)'),
    ["v|<Leader>cf"]     = ro:map_cmd('<Plug>(coc-format-selected)'),
    ["n|<Leader>cf"]     = ro:map_cmd('<Plug>(coc-format-selected)'),
    ["n|gd"]             = ro:map_cu('call initself#definition_other_window()'):with_silent(),
    ["n|gy"]             = ro:map_cmd('<Plug>(coc-type-definition)'):with_silent(),
    ["n|<Leaderci>"]     = ro:map_cmd('<Plug>(coc-implementation)'),
    ["n|gr"]             = ro:map_cmd('<Plug>(coc-references)'):with_silent(),
    ["n|K"]              = ro:map_cr("call CocActionAsync('doHover')"):with_silent(),
    ["n|]g"]             = ro:map_cmd('<Plug>(coc-git-prevchunk)'),
    ["n|[g"]             = ro:map_cmd('<Plug>(coc-git-nextchunk)'),
    ["n|<Leader>gi"]     = ro:map_cmd('<Plug>(coc-git-chunkinfo)'),
    ["n|<Leader>gm"]     = ro:map_cmd('<Plug>(coc-git-commit)'),
    ["n|<M-s>"]          = ro:map_cmd('<Plug>(coc-cursors-position)'):with_silent(),
    ["n|<M-d>"]          = ro:map_cmd('initself#select_current_word()'),
    ["x|<M-d>"]          = ro:map_cmd("<Plug>(coc-cursors-range)"):with_silent(),
    ["n|<M-c>"]          = ro:map_cmd("Plug>(coc-cursors-operator)"):with_silent(),
    ["n|<Leader>fz"]     = ro:map_cmd(":<C-u>CocSearch -w<Space>"):with_noremap():with_silent(),
    ["n|gcj"]            = ro:map_cr("execute 'CocCommand docthis.documentThis'"),
    -- Plugin Defx
    ["n|<Leader>e"]      = ro:map_cu([[Defx -resume -toggle -buffer-name=tab`tabpagenr()`]]):with_noremap():with_silent(),
    ["n|<Leader>F"]      = ro:map_cu([[Defx -resume -buffer-name=tab`tabpagenr()` -search=`expand('%:p')`]]):with_noremap():with_silent(),
    -- Plugin MarkdownPreview
    ["n|<Leader>om"]     = ro:map_cu('MarkdownPreview'):with_noremap():with_silent(),
    -- Plugin DadbodUI
    ["n|<Leader>od"]     = ro:map_cr('DBUIToggle'):with_noremap():with_silent(),
    -- Plugin Floaterm
    ["n|<Leader>t"]      = ro:map_cu('FloatermToggle'):with_noremap():with_silent(),
    ["n|<Leader>g"]      = ro:map_cu('FloatermNew height=0.7 width=0.8 lazygit'):with_noremap():with_silent(),
    -- Plugin Coc-Clap
    ["n|<Leader>ce"]     = ro:map_cr('Clap coc_diagnostics'):with_noremap():with_silent(),
    ["n|<Leader>;"]      = ro:map_cr('Clap coc_extensions'):with_noremap():with_silent(),
    ["n|<Leader>,"]      = ro:map_cr('Clap coc_commands'):with_noremap():with_silent(),
    ["n|<Leader>cs"]     = ro:map_cr('Clap coc_symbols'):with_noremap():with_silent(),
    ["n|<Leader>cS"]     = ro:map_cr('Clap coc_services'):with_noremap():with_silent(),
    ["n|<Leader>ct"]     = ro:map_cr('Clap coc_outline'):with_noremap():with_silent(),
    -- Plugin Clap
    ["n|<Leader>tc"]     = ro:map_cu('Clap colors'):with_noremap():with_silent(),
    ["n|<Leader>bb"]     = ro:map_cu('Clap bufers'):with_noremap():with_silent(),
    ["n|<Leader>fa"]     = ro:map_cu('Clap grep'):with_noremap():with_silent(),
    ["n|<Leader>fb"]     = ro:map_cu('Clap marks'):with_noremap():with_silent(),
    ["n|<C-x><C-f>"]     = ro:map_cu('Clap filer'):with_noremap():with_silent(),
    ["n|<Leader>ff"]     = ro:map_cu('Clap files ++finder=rg --ignore --hidden --files'):with_noremap():with_silent(),
    ["n|<Leader>fg"]     = ro:map_cu('Clap gfiles'):with_noremap():with_silent(),
    ["n|<Leader>fw"]     = ro:map_cu('Clap grep ++query=<Cword>'):with_noremap():with_silent(),
    ["n|<Leader>fh"]     = ro:map_cu('Clap history'):with_noremap():with_silent(),
    ["n|<Leader>fW"]     = ro:map_cu('Clap windows'):with_noremap():with_silent(),
    ["n|<Leader>fl"]     = ro:map_cu('Clap loclist'):with_noremap():with_silent(),
    ["n|<Leader>fu"]     = ro:map_cu('Clap git_diff_files'):with_noremap():with_silent(),
    ["n|<Leader>fv"]     = ro:map_cu('Clap grep ++query=@visual'):with_noremap():with_silent(),
    ["n|<Leader>oc"]     = ro:map_cu('Clap dotfiles'):with_noremap():with_silent(),
    ["n|<LocalLeader>g"] = ro:map_cu('Clap gosource'):with_noremap():with_silent(),
    -- Plugin acceleratedjk
    ["n|j"]              = ro:map_cmd('<Plug>(accelerated_jk_gj)'),
    ["n|k"]              = ro:map_cmd('<Plug>(accelerated_jk_gk)'),
    -- Plugin QuickRun
    ["n|<Leader>cr"]     = ro:map_cr('QuickRun'):with_noremap():with_silent(),
    -- Plugin Vista
    ["n|<Leader>i"]      = ro:map_cu('Vista!!'):with_noremap():with_silent(),
    -- Plugin Easymotion
    ["n|gsj"]            = ro:map_cmd('<Plug>(easymotion-w)'),
    ["n|gsk"]            = ro:map_cmd('<Plug>(easymotion-b)'),
    ["n|gsf"]            = ro:map_cmd('<Plug>(easymotion-overwin-f)'),
    ["n|gss"]            = ro:map_cmd('<Plug>(easymotion-overwin-f2)'),
    -- Plugin Mundo
    ["n|<Leader>m"]      = ro:map_cu('MundoToggle'):with_noremap():with_silent(),
    -- Plugin SplitJoin
    ["n|sj"]             = ro:map_cmd('SplitjoinJoin'),
    ["n|sk"]             = ro:map_cmd('SplitjoinSplit'),
    -- Plugin dsf
    ["n|dsf"]            = ro:map_cmd('<Plug>DsfDelete'),
    ["n|csf"]            = ro:map_cmd('<Plug>DsfChange'),
    -- Plugin go-nvim
    ["n|gcg"]            = ro:map_cr('GoAutoComment'):with_noremap():with_silent(),
    -- Plugin vim-textobj-function
    ["o|af"]             = ro:map_cmd("<Plug>(textobj-function-a)"):with_silent(),
    ["o|if"]             = ro:map_cmd("<Plug>(textobj-function-i)"):with_silent(),
    ["x|af"]             = ro:map_cmd("<Plug>(textobj-function-a)"):with_silent(),
    ["x|af"]             = ro:map_cmd("<Plug>(textobj-function-i)"):with_silent(),
    ["x|I"]              = ro:map_cmd("niceblock-I"),
    ["x|A"]              = ro:map_cmd("niceblock-A"),
    ["x|p"]              = ro:map_cmd("<Plug>(operator-replace)"),
    -- Plugin sandwich
    ["n|sa"]             = ro:map_cmd("<Plug>(operator-sandwich-add)"):with_silent(),
    ["x|sa"]             = ro:map_cmd("<Plug>(operator-sandwich-add)"):with_silent(),
    ["o|sa"]             = ro:map_cmd("<Plug>(operator-sandwich-g@)"):with_silent(),
    ["n|sd"]             = ro:map_cmd("<Plug>(operator-sandwich-delete)<Plug>(operator-sandwich-release-count)<Plug>(textobj-sandwich-query-a)"):with_silent(),
    ["x|sd"]             = ro:map_cmd("<Plug>(operator-sandwich-delete)"):with_silent(),
    ["n|sr"]             = ro:map_cmd("<Plug>(operator-sandwich-replace)<Plug>(operator-sandwich-release-count)<Plug>(textobj-sandwich-query-a)"):with_silent(),
    ["x|sr"]             = ro:map_cmd("<Plug>(operator-sandwich-replace)"):with_silent(),
    ["n|sdb"]            = ro:map_cmd("<Plug>(operator-sandwich-delete)<Plug>(operator-sandwich-release-count)<Plug>(textobj-sandwich-auto-a)"):with_silent(),
    ["n|srb"]            = ro:map_cmd("<Plug>(operator-sandwich-replace)<Plug>(operator-sandwich-release-count)<Plug>(textobj-sandwich-auto-a)"):with_silent(),
    ["o|ib"]             = ro:map_cmd("<Plug>(textobj-sandwich-auto-i)"),
    ["x|ib"]             = ro:map_cmd("<Plug>(textobj-sandwich-auto-i)"),
    ["o|ab"]             = ro:map_cmd("<Plug>(textobj-sandwich-auto-a)"),
    ["x|ab"]             = ro:map_cmd("<Plug>(textobj-sandwich-auto-a)"),
    ["o|is"]             = ro:map_cmd("<Plug>(textobj-sandwich-query-i)"),
    ["x|is"]             = ro:map_cmd("<Plug>(textobj-sandwich-query-i)"),
    ["o|as"]             = ro:map_cmd("<Plug>(textobj-sandwich-query-a)"),
    ["x|as"]             = ro:map_cmd("<Plug>(textobj-sandwich-query-a)"),
  };
end

function mapping:load_mapping()
  self:load_vim_define()
  self:load_plugin_define()
  for k,v in pairs(self) do
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
  instance = {}
  setmetatable(instance,self)
  self.__index = self
  self.cmd = ''
  self.options = {
    noremap = false,
    silent = false,
    expr   = false,
  }
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
