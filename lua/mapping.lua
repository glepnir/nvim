require 'global'

mapping = {}

function mapping:new()
  instance = {}
  setmetatable(instance, self)
  self.__index = self
  self.vim    = {}
  self.plugin = {}
  return instance
end

function mapping:load_vim_define()
  self.vim = {
    -- Vim map
    ["n|<C-x>k"]     = map_not_recursive_cr('BD'),
    ["n|<C-s>"]      = map_not_recursive_cu('write'),
    ["n|Y"]          = map_not_recursive('y$'),
    ["n|]w"]         = map_not_recursive_cu('WhitespaceNext'),
    ["n|[w"]         = map_not_recursive_cu('WhitespacePrev'),
    ["n|]b"]         = map_not_recursive_cu('bp'),
    ["n|[b"]         = map_not_recursive_cu('bn'),
    ["n|<Space>cw"]  = map_not_recursive_silentcu([[silent! keeppatterns %substitute/\s\+$//e]]),
    ["n|<C-h>"]      = map_not_recursive('<C-w>h'),
    ["n|<C-l>"]      = map_not_recursive('<C-w>l'),
    ["n|<C-j>"]      = map_not_recursive('<C-w>j'),
    ["n|<C-k>"]      = map_not_recursive('<C-w>k'),
    ["n|<C-w>["]     = map_recursive_cr('vertical resize -3'),
    ["n|<C-w>]"]     = map_recursive_cr('vertical resize +3'),
    ["n|<Leader>ss"] = map_not_recursive_cu('SessionSave'),
    ["n|<Leader>sl"] = map_not_recursive_cu('SessionLoad'),
  -- Insert
    ["i|<C-w>"]      = map_not_recursive('<C-[>diwa'),
    ["i|<C-h>"]      = map_not_recursive('<BS>'),
    ["i|<C-d>"]      = map_not_recursive('<Del>'),
    ["i|<C-k>"]      = map_not_recursive('<ESC>d$a'),
    ["i|<C-u>"]      = map_not_recursive('<C-G>u<C-U>'),
    ["i|<C-b>"]      = map_not_recursive('<Left>'),
    ["i|<C-f>"]      = map_not_recursive('<Right>'),
    ["i|<C-a>"]      = map_not_recursive('<ESC>^i'),
    ["i|<C-o>"]      = map_not_recursive('<Esc>o'),
    ["i|<C-s>"]      = map_recursive('<Esc>:w<CR>'),
    ["i|<C-q>"]      = map_recursive('<Esc>:wq<CR>'),
    ["i|<C-e>"]      = map_not_recursive_expr([[pumvisible() ? "\<C-e>" : "\<End>"]]),
  -- command line
    ["c|<C-b>"]      = map_not_recursive('<Left>'),
    ["c|<C-f>"]      = map_not_recursive('<Right>'),
    ["c|<C-a>"]      = map_not_recursive('<Home>'),
    ["c|<C-e>"]      = map_not_recursive('<End>'),
    ["c|<C-d>"]      = map_not_recursive('<Del>'),
    ["c|<C-h>"]      = map_not_recursive('<BS>'),
    ["c|<C-t>"]      = map_not_recursive([[<C-R>=expand("%:p:h") . "/" <CR>]]),
  };
end

function mapping:load_plugin_define()
  self.plugin = {
    ["n|<Leader>tf"]     = map_not_recursive_silentcu('DashboardNewFile'),
    ["n|<Leader>bc"]     = map_not_recursive_silentcr('Bonly'),
    ["n|<Leader>bx"]     = map_not_recursive_silentcr('Bw'),
    ["n|<Leader>,0,9"]   = '<Plug>BuffetSwitch(+)',
    -- Plugin Coc
    ["x|<Leader>a"]      = map_recursive_silentcu("execute 'CocCommand actions.open ' . visualmode()"),
    ["n|<Leader>a"]      = map_recursive_silent(":<C-u>set operatorfunc=initself#coc_action_select<CR>g@"),
    ["n|]e"]             = map_recursive_silent('<Plug>(coc-diagnostic-prev)'),
    ["n|[e"]             = map_recursive_silent('<Plug>(coc-diagnostic-next)'),
    ["n|<Leader>cr"]     = map_recursive('<Plug>(coc-rename)'),
    ["v|<Leader>cf"]     = map_recursive('<Plug>(coc-format-selected)'),
    ["n|<Leader>cf"]     = map_recursive('<Plug>(coc-format-selected)'),
    ["n|gd"]             = map_recursive_silentcu('call initself#definition_other_window()'),
    ["n|gy"]             = map_recursive_silent('<Plug>(coc-type-definition)'),
    ["n|<Leaderci>"]     = map_recursive('<Plug>(coc-implementation)'),
    ["n|gr"]             = map_recursive_silent('<Plug>(coc-references)'),
    ["n|K"]              = map_recursive_silentcr("call CocActionAsync('doHover')"),
    ["n|]g"]             = map_recursive('<Plug>(coc-git-prevchunk)'),
    ["n|[g"]             = map_recursive('<Plug>(coc-git-nextchunk)'),
    ["n|<Leader>gi"]     = map_recursive('<Plug>(coc-git-chunkinfo)'),
    ["n|<Leader>gm"]     = map_recursive('<Plug>(coc-git-commit)'),
    ["n|<M-s>"]          = map_recursive_silent('<Plug>(coc-cursors-position)'),
    ["n|<M-d>"]          = map_recursive_expr('initself#select_current_word()'),
    ["x|<M-d>"]          = map_recursive_silent("<Plug>(coc-cursors-range)"),
    ["n|<M-c>"]          = map_recursive_silent("Plug>(coc-cursors-operator)"),
    ["n|<Leader>fz"]     = map_not_recursive_silent(":<C-u>CocSearch -w<Space>"),
    ["n|gcj"]            = map_recursive_cr("execute 'CocCommand docthis.documentThis'"),
    -- Plugin Defx
    ["n|<Leader>e"]      = map_not_recursive_silentcu([[Defx -resume -toggle -buffer-name=tab`tabpagenr()`]]),
    ["n|<Leader>F"]      = map_not_recursive_silentcu([[Defx -resume -buffer-name=tab`tabpagenr()` -search=`expand('%:p')`]]),
    -- Plugin MarkdownPreview
    ["n|<Leader>om"]     = map_not_recursive_silentcu('MarkdownPreview'),
    -- Plugin DadbodUI
    ["n|<Leader>od"]     = map_not_recursive_silentcr('DBUIToggle'),
    -- Plugin Floaterm
    ["n|<Leader>t"]      = map_not_recursive_silentcu('FloatermToggle'),
    ["n|<Leader>g"]      = map_not_recursive_silentcu('FloatermNew height=0.7 width=0.8 lazygit'),
    -- Plugin Coc-Clap
    ["n|<Leader>ce"]     = map_not_recursive_silentcr('Clap coc_diagnostics'),
    ["n|<Leader>;"]      = map_not_recursive_silentcr('Clap coc_extensions'),
    ["n|<Leader>,"]      = map_not_recursive_silentcr('Clap coc_commands'),
    ["n|<Leader>cs"]     = map_not_recursive_silentcr('Clap coc_symbols'),
    ["n|<Leader>cS"]     = map_not_recursive_silentcr('Clap coc_services'),
    ["n|<Leader>ct"]     = map_not_recursive_silentcr('Clap coc_outline'),
    -- Plugin Clap
    ["n|<Leader>tc"]     = map_not_recursive_silentcu('Clap colors'),
    ["n|<Leader>bb"]     = map_not_recursive_silentcu('Clap bufers'),
    ["n|<Leader>fa"]     = map_not_recursive_silentcu('Clap grep'),
    ["n|<Leader>fb"]     = map_not_recursive_silentcu('Clap marks'),
    ["n|<C-x><C-f>"]     = map_not_recursive_silentcu('Clap filer'),
    ["n|<Leader>ff"]     = map_not_recursive_silentcu('Clap files ++finder=rg --ignore --hidden --files'),
    ["n|<Leader>fg"]     = map_not_recursive_silentcu('Clap gfiles'),
    ["n|<Leader>fw"]     = map_not_recursive_silentcu('Clap grep ++query=<Cword>'),
    ["n|<Leader>fh"]     = map_not_recursive_silentcu('Clap history'),
    ["n|<Leader>fW"]     = map_not_recursive_silentcu('Clap windows'),
    ["n|<Leader>fl"]     = map_not_recursive_silentcu('Clap loclist'),
    ["n|<Leader>fu"]     = map_not_recursive_silentcu('Clap git_diff_files'),
    ["n|<Leader>fv"]     = map_not_recursive_silentcu('Clap grep ++query=@visual'),
    ["n|<Leader>oc"]     = map_not_recursive_silentcu('Clap dotfiles'),
    ["n|<LocalLeader>g"] = map_not_recursive_silentcu('Clap gosource'),
    -- Plugin acceleratedjk
    ["n|j"]              = map_recursive('<Plug>(accelerated_jk_gj)'),
    ["n|k"]              = map_recursive('<Plug>(accelerated_jk_gk)'),
    -- Plugin QuickRun
    ["n|<Leader>cr"]     = map_not_recursive_silentcr('QuickRun'),
    -- Plugin Vista
    ["n|<Leader>i"]      = map_not_recursive_silentcu('Vista!!'),
    -- Plugin Easymotion
    ["n|gsj"]            = map_recursive('<Plug>(easymotion-w)'),
    ["n|gsk"]            = map_recursive('<Plug>(easymotion-b)'),
    ["n|gsf"]            = map_recursive('<Plug>(easymotion-overwin-f)'),
    ["n|gss"]            = map_recursive('<Plug>(easymotion-overwin-f2)'),
    -- Plugin Mundo
    ["n|<Leader>m"]      = map_not_recursive_silentcu('MundoToggle'),
    -- Plugin SplitJoin
    ["n|sj"]             = map_recursive('SplitjoinJoin'),
    ["n|sk"]             = map_recursive('SplitjoinSplit'),
    -- Plugin dsf
    ["n|dsf"]            = map_recursive('<Plug>DsfDelete'),
    ["n|csf"]            = map_recursive('<Plug>DsfChange'),
    -- Plugin go-nvim
    ["n|gcg"]            = map_not_recursive_silentcr('GoAutoComment'),
    -- Plugin vim-textobj-function
    ["o|af"]             = map_recursive_silent("<Plug>(textobj-function-a)"),
    ["o|if"]             = map_recursive_silent("<Plug>(textobj-function-i)"),
    ["x|af"]             = map_recursive_silent("<Plug>(textobj-function-a)"),
    ["x|af"]             = map_recursive_silent("<Plug>(textobj-function-i)"),
    ["x|I"]              = map_recursive("niceblock-I"),
    ["x|A"]              = map_recursive("niceblock-A"),
    ["x|p"]              = map_recursive("<Plug>(operator-replace)"),
    -- Plugin sandwich
    ["n|sa"]             = map_recursive_silent("<Plug>(operator-sandwich-add)"),
    ["x|sa"]             = map_recursive_silent("<Plug>(operator-sandwich-add)"),
    ["o|sa"]             = map_recursive_silent("<Plug>(operator-sandwich-g@)"),
    ["n|sd"]             = map_recursive_silent("<Plug>(operator-sandwich-delete)<Plug>(operator-sandwich-release-count)<Plug>(textobj-sandwich-query-a)"),
    ["x|sd"]             = map_recursive_silent("<Plug>(operator-sandwich-delete)"),
    ["n|sr"]             = map_recursive_silent("<Plug>(operator-sandwich-replace)<Plug>(operator-sandwich-release-count)<Plug>(textobj-sandwich-query-a)"),
    ["x|sr"]             = map_recursive_silent("<Plug>(operator-sandwich-replace)"),
    ["n|sdb"]            = map_recursive_silent("<Plug>(operator-sandwich-delete)<Plug>(operator-sandwich-release-count)<Plug>(textobj-sandwich-auto-a)"),
    ["n|srb"]            = map_recursive_silent("<Plug>(operator-sandwich-replace)<Plug>(operator-sandwich-release-count)<Plug>(textobj-sandwich-auto-a)"),
    ["o|ib"]             = map_recursive("<Plug>(textobj-sandwich-auto-i)"),
    ["x|ib"]             = map_recursive("<Plug>(textobj-sandwich-auto-i)"),
    ["o|ab"]             = map_recursive("<Plug>(textobj-sandwich-auto-a)"),
    ["x|ab"]             = map_recursive("<Plug>(textobj-sandwich-auto-a)"),
    ["o|is"]             = map_recursive("<Plug>(textobj-sandwich-query-i)"),
    ["x|is"]             = map_recursive("<Plug>(textobj-sandwich-query-i)"),
    ["o|as"]             = map_recursive("<Plug>(textobj-sandwich-query-a)"),
    ["x|as"]             = map_recursive("<Plug>(textobj-sandwich-query-a)"),
  };
end

function mapping:load_mapping()
  self:load_vim_define()
  self:load_plugin_define()
  for k,v in pairs(self) do
    for key,value in pairs(v) do
      local mode,keymap = key:match("([^|]*)|?(.*)")
      if type(value) == 'table' then
        rhs = value[1]
        options = vim.tbl_extend("keep",value[2],default_options or {})
        vim.api.nvim_set_keymap(mode,keymap,rhs,options)
      elseif type(value) == 'string' then
        local k,min,max = keymap:match("([^,]+),([^,]+),([^,]+)")
        for i=tonumber(min),tonumber(max) do
          key = (k.."%s"):format(i)
          rhs = value:gsub("+",i)
          vim.api.nvim_set_keymap(mode,key,rhs,{})
        end
      end
    end
  end
end
