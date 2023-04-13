--SOLARIZED HEX     16/8 TERMCOL  XTERM/HEX   L*A*B      sRGB        HSB
----------- ------- ---- -------  ----------- ---------- ----------- -----------
--base03    #002b36  8/4 brblack  234 #1c1c1c 15 -12 -12   0  43  54 193 100  21
--base02    #073642  0/4 black    235 #262626 20 -12 -12   7  54  66 192  90  26
--base01    #586e75 10/7 brgreen  240 #4e4e4e 45 -07 -07  88 110 117 194  25  46
--base00    #657b83 11/7 bryellow 241 #585858 50 -07 -07 101 123 131 195  23  51
--base0     #839496 12/6 brblue   244 #808080 60 -06 -03 131 148 150 186  13  59
--base1     #93a1a1 14/4 brcyan   245 #8a8a8a 65 -05 -02 147 161 161 180   9  63
--base2     #eee8d5  7/7 white    254 #d7d7af 92 -00  10 238 232 213  44  11  93
--base3     #fdf6e3 15/7 brwhite  230 #ffffd7 97  00  10 253 246 227  44  10  99
--yellow    #b58900  3/3 yellow   136 #af8700 60  10  65 181 137   0  45 100  71
--orange    #cb4b16  9/3 brred    166 #d75f00 50  50  55 203  75  22  18  89  80
--red       #dc322f  1/1 red      160 #d70000 50  65  45 220  50  47   1  79  86
--magenta   #d33682  5/5 magenta  125 #af005f 50  65 -05 211  54 130 331  74  83
--violet    #6c71c4 13/5 brmagenta 61 #5f5faf 50  15 -45 108 113 196 237  45  77
--blue      #268bd2  4/4 blue      33 #0087ff 55 -10 -45  38 139 210 205  82  82
--cyan      #2aa198  6/6 cyan      37 #00afaf 60 -35 -05  42 161 152 175  74  63
--green     #859900  2/2 green     64 #5f8700 60 -20  65 133 153   0  68 100  60

local function palette()
  return {
    base03 = '#002b36',
    base02 = '#073642',
    base01 = '#586e75',
    base00 = '#657b83',
    --#839496 hsv(186°, 13%, 59%)
    --#86999c is hsv(186°, 14%, 61%)
    base0 = '#839496',
    base1 = '#93a1a1',
    base2 = '#eee8d5',
    base3 = '#fdf6e3',
    red = '#dc322f',
    dorange = '#cb4b16',
    orange = '#d1702a',
    yellow = '#b58900',
    magenta = '#d33682',
    violet = '#957FB8',
    blue = '#268bd2',
    cyan = '#2aa198',
    --based on base0 hsv(188°, 68%, 68%)
    dcyan = '#379ead',
    green = '#859900',
    non = 'NONE',
  }
end

local function in_vim(groups, p)
  local g, api, opt = vim.g, vim.api, vim.opt
  g.terminal_color_0 = p.base05
  g.terminal_color_1 = p.red
  g.terminal_color_2 = p.green
  g.terminal_color_3 = p.yellow
  g.terminal_color_4 = p.blue
  g.terminal_color_5 = p.magenta
  g.terminal_color_6 = p.cyan
  g.terminal_color_7 = p.base3
  g.terminal_color_8 = p.base01
  g.terminal_color_9 = p.orange
  g.terminal_color_10 = p.base00
  g.terminal_color_11 = p.base0
  g.terminal_color_12 = p.base1
  g.terminal_color_13 = p.violet
  g.terminal_color_14 = p.base2
  g.terminal_color_15 = p.base3

  api.nvim_command('hi clear')
  opt.background = 'dark'
  opt.termguicolors = true
  g.colors_name = 'solarized'
  for _, v in pairs(groups) do
    vim.api.nvim_set_hl(0, v[1], v[2])
  end
end

local function colorscheme()
  local p = palette()

  local groups = {
    --Neovim Relate
    { 'Normal', { fg = p.base0, bg = p.base03 } },
    --signcolumn
    { 'SignColumn', { bg = p.base03 } },
    --buffer
    { 'LineNr', { fg = p.base01 } },
    { 'EndOfBuffer', { bg = p.non, fg = p.base03 } },
    { 'Search', { fg = p.yellow, reverse = true } },
    { 'Visual', { bg = p.base02 } },
    { 'ColorColumn', { bg = p.base02 } },
    { 'Whitespace', { fg = p.base02 } },
    --window
    { 'VertSplit', { fg = p.base02 } },
    { 'Title', { fg = p.orange, bold = true } },
    --cursorline
    { 'Cursorline', { bg = p.base02 } },
    { 'CursorLineNr', { fg = p.base0 } },
    --pmenu
    { 'Pmenu', { bg = p.base02, fg = p.base1 } },
    { 'PmenuSel', { fg = p.base2, bg = p.base00 } },
    { 'PmenuSbar', { bg = '#586e75' } },
    { 'PmenuThumb', { bg = p.base0 } },
    { 'PmenuKind', { bg = p.base02, fg = p.yellow } },
    { 'PmenuKindSel', { link = 'PmenuSel' } },
    { 'PmenuExtra', { link = 'Pmenu' } },
    { 'PmenuExtraSel', { link = 'PmenuSel' } },
    { 'WildMenu', { link = 'pmenu' } },
    --statusline
    { 'StatusLine', { bg = p.base02 } },
    { 'StatusLineNC', { fg = p.base02, bg = p.base05 } },
    { 'WinBar', { bg = p.non } },
    { 'WinBarNC', { bg = p.non } },
    --Error
    { 'ErrorMsg', { link = 'Error' } },
    --Markup
    { 'TODO', { fg = p.magenta } },
    { 'Conceal', { fg = p.blue } },
    { 'Error', { fg = p.red, bold = true } },
    { 'NonText', { link = 'Comment' } },
    --Float
    { 'FloatBorder', { fg = p.blue } },
    { 'FloatNormal', { link = 'Normal' } },
    { 'FloatShadow', { bg = p.base06 } },
    --Fold
    { 'Folded', { fg = p.base0, bold = true } },
    { 'FoldColumn', { link = 'SignColumn' } },
    --Spell
    { 'SpellBad', { fg = p.magenta } },
    { 'SpellCap', { undercurl = true, fg = p.magenta } },
    { 'SpellRare', { undercurl = true, sp = p.violet } },
    { 'SpellLocal', { undercurl = true } },
    --Msg
    { 'WarningMsg', { fg = p.magenta } },
    { 'MoreMsg', { fg = p.green } },
    --Internal
    { 'NvimInternalError', { fg = p.red } },
    { 'Directory', { fg = p.blue } },
    --------------------------------------------------------
    ---@Langauge Relate
    ---@Identifier
    { 'Identifier', { fg = p.blue } },
    -- various variable names
    { '@variable', { fg = p.base0 } },
    --built-in variable names (e.g. `this`)
    { '@variable.builtin', { fg = p.green, bold = true } },
    { 'Constant', { fg = p.orange } },
    { '@constant.builtin', { link = 'Constant' } },
    -- constants defined by the preprocessor
    { '@constant.macro', {} },
    --modules or namespaces
    { '@namespace', { link = 'Include' } },
    --symbols or atoms
    -- ['@symbol'] = {},
    --------------------------------------------------------
    ---@Keywords
    { 'Keyword', { fg = p.green } },
    { '@keyword.function', { fg = p.dorange } },
    { '@keyword.return', { fg = p.green } },
    { '@keyword.operator', { link = 'Operator' } },
    --if else
    { 'Conditional', { link = 'Keyword' } },
    --for while
    { 'Repeat', { link = 'Conditional' } },

    { 'Debug', { fg = p.dorange } },
    { 'Label', { fg = p.violet } },
    { 'PreProc', { fg = p.dorange } },
    { 'Include', { link = 'PreProc' } },
    { 'Exception', { fg = p.violet } },
    { 'Statement', { fg = p.green } },
    { 'SpecialKey', { fg = p.dorange } },
    { 'Special', { fg = p.dorange } },
    --------------------------------------------------------
    ---@Types
    { 'Type', { fg = p.yellow } },
    { '@type.builtin', { link = 'Type' } },
    --type definitions (e.g. `typedef` in C)
    { '@type.definition', { link = 'Type' } },
    --type qualifiers (e.g. `const`)
    { '@type.qualifier', { fg = p.green } },
    --modifiers that affect storage in memory or life-time like C `static`
    { '@storageclass', { link = 'Keyword' } },
    { '@field', { fg = p.dcyan } },
    { '@property', { link = '@field' } },
    --------------------------------------------------------
    ---@Functions
    { 'Function', { fg = p.blue } },
    --built-in functions
    { '@function.builtin', { link = 'Function' } },
    --function calls
    { '@function.call', { link = 'Function' } },
    --preprocessor macros
    { '@function.macro', { link = 'Function' } },
    { '@method', { link = 'Function' } },
    { '@method.call', { link = 'Function' } },
    { '@constructor', { fg = p.violet } },
    { '@parameter', { link = '@variable' } },
    --------------------------------------------------------
    ---@Literals
    { 'String', { fg = p.cyan } },
    { 'Number', { fg = p.violet } },
    { 'Float', { link = 'Number' } },
    { 'Boolean', { link = 'Number' } },
    --
    { 'Define', { link = 'PreProc' } },
    { 'Operator', { fg = '#8c8027' } },
    { 'Comment', { fg = p.base01 } },
    --------------------------------------------------------
    ---@punctuation
    { '@punctuation.bracket', { fg = p.base00 } },
    { '@punctuation.delimiter', { link = '@punctuation.bracket' } },
    --------------------------------------------------------
    ---@Tag
    { '@tag.html', { fg = p.orange } },
    { '@tag.attribute.html', { link = '@property' } },
    { '@tag.delimiter.html', { link = '@punctuation.delimiter' } },
    { '@tag.javascript', { link = '@tag.html' } },
    { '@tag.attribute.javascript', { link = '@tag.attribute.html' } },
    { '@tag.delimiter.javascript', { link = '@tag.delimiter.html' } },
    { '@tag.typescript', { link = '@tag.html' } },
    { '@tag.attribute.typescript', { link = '@tag.attribute.html' } },
    { '@tag.delimiter.typescript', { link = '@tag.delimiter.html' } },
    --------------------------------------------------------
    --------------------------------------------------------
    ---@Markdown
    { '@text.reference.markdown_inline', { fg = p.blue } },
    ---@Diff
    { 'DiffAdd', { fg = p.green } },
    { 'DiffChange', { fg = p.blue } },
    { 'DiffDelete', { fg = p.dorange } },
    { 'DiffText', { fg = p.dorange } },
    { 'diffAdded', { fg = p.green } },
    { 'diffRemoved', { fg = p.dorange } },
    { 'diffChanged', { fg = p.blue } },
    { 'diffOldFile', { fg = p.yellow } },
    { 'diffNewFile', { fg = p.orange } },
    { 'diffFile', { fg = p.cyan } },
    --------------------------------------------------------
    ---@Diagnostic
    { 'DiagnosticError', { link = 'Error' } },
    { 'DiagnosticWarn', { fg = p.yellow } },
    { 'DiagnosticInfo', { fg = p.blue } },
    { 'DiagnosticHint', { fg = '#4eacb5' } },
    { 'DiagnosticSignError', { link = 'DiagnosticError' } },
    { 'DiagnosticSignWarn', { link = 'DiagnosticWarn' } },
    { 'DiagnosticSignInfo', { link = 'DiagnosticInfo' } },
    { 'DiagnosticSignHint', { link = 'DiagnosticHint' } },
    { 'DiagnosticUnderlineError', { undercurl = true } },
    { 'DiagnosticUnderlineWarn', { undercurl = true } },
    { 'DiagnosticUnderlineInfo', { undercurl = true } },
    { 'DiagnosticUnderlineHint', { undercurl = true } },
    ---@plugin
    { 'GitGutterAdd', { fg = p.green } },
    { 'GitGutterChange', { fg = p.blue } },
    { 'GitGutterDelete', { fg = p.red } },
    { 'GitGutterChangeDelete', { fg = p.red } },
    --dashboard
    { 'DashboardHeader', { fg = p.violet } },
    { 'DashboardFooter', { link = 'Comment' } },
    { 'DashboardProjectTitle', { fg = p.yellow, bold = true } },
    { 'DashboardProjectTitleIcon', { fg = p.violet } },
    { 'DashboardProjectIcon', { fg = p.blue } },
    { 'DashboardMruTitle', { link = 'DashboardProjectTitle' } },
    { 'DashboardMruIcon', { link = 'DashboardProjectTitleIcon' } },
    { 'DashboardFiles', { fg = p.base0 } },
    { 'DashboardShortCut', { link = 'Comment' } },
    { 'DashboardShortCutIcon', { link = '@field' } },
    --Telescope
    { 'TelescopePromptBorder', { bg = p.base02, fg = p.base02 } },
    { 'TelescopePromptNormal', { bg = p.base02, fg = p.dorange } },
    { 'TelescopeResultsBorder', { bg = p.base02, fg = p.base02 } },
    { 'TelescopePreviewBorder', { bg = p.base02, fg = p.base02 } },
    { 'TelescopeResultsNormal', { fg = p.base0 } },
    { 'TelescopeSelectionCaret', { fg = p.yellow } },
    { 'TelescopeMatching', { fg = p.yellow } },
    --CursorWord
    { 'CursorWord', { bg = p.base02 } },
    { 'IndentLine', { link = 'Comment' } },
    --Lspsaga
    { 'SagaWinbarVariable', { fg = p.green } },
  }

  in_vim(groups, p)
end

return {
  colorscheme = colorscheme,
}
