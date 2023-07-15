local g, api, opt = vim.g, vim.api, vim.opt

local function palette()
  return {
    bg = '#1d1d1d',
    bg_alt = '#303030',
    fg = '#cccccc',
    fg_dim = '#989898',
    fg_alt = '#75715E',
    red = '#ff5f59',
    --H 30  S 80 V 90
    orange = '#cc7a29',
    yellow = '#e6b045',
    --H 70  S 80 V 80
    green = '#b1cc29',
    --H 190 S 60 V 80
    cyan = '#52b8cc',
    --H 210 S 60 V 90
    blue = '#5ca1e6',
    --H 260 S 40 V 80
    purple = '#957acc',
    teal = '#52ccb0',
  }
end

local function in_vim(groups, p)
  g.terminal_color_0 = p.bg_alt
  g.terminal_color_1 = p.red
  g.terminal_color_2 = p.green
  g.terminal_color_3 = p.yellow
  g.terminal_color_4 = p.blue
  g.terminal_color_5 = p.purple
  g.terminal_color_6 = p.cyan
  g.terminal_color_7 = p.bg
  g.terminal_color_8 = p.base01
  g.terminal_color_9 = p.orange
  g.terminal_color_10 = p.base00
  g.terminal_color_11 = p.base0
  g.terminal_color_12 = p.base1
  g.terminal_color_13 = p.violet
  g.terminal_color_14 = p.base2
  g.terminal_color_15 = p.base3
end

local function colorscheme()
  local p = palette()

  local groups = {
    --Neovim Relate
    { 'Normal', { fg = p.fg, bg = p.bg } },
    --signcolumn
    { 'SignColumn', { bg = p.bg } },
    --buffer
    { 'LineNr', { fg = p.bg_alt } },
    { 'EndOfBuffer', { bg = p.non, fg = p.bg } },
    { 'Search', { fg = p.yellow, reverse = true } },
    { 'Visual', { bg = p.bg_dim } },
    { 'ColorColumn', { bg = p.bg_dim } },
    { 'Whitespace', { fg = p.bg_alt } },
    --window
    { 'VertSplit', { fg = p.bg_dim } },
    { 'Title', { fg = p.orange, bold = true } },
    --cursorline
    { 'Cursorline', { bg = p.bg_alt } },
    { 'CursorLineNr', { fg = p.fg_alt } },
    --pmenu
    { 'Pmenu', { bg = p.bg_alt, fg = p.fg_dim } },
    { 'PmenuSel', { fg = p.bg_alt, bg = p.bg } },
    { 'PmenuSbar', { bg = '#586e75' } },
    { 'PmenuThumb', { bg = p.bg } },
    { 'PmenuKind', { bg = p.bg_alt, fg = p.yellow } },
    { 'PmenuKindSel', { link = 'PmenuSel' } },
    { 'PmenuExtra', { link = 'Pmenu' } },
    { 'PmenuExtraSel', { link = 'PmenuSel' } },
    { 'WildMenu', { link = 'pmenu' } }, --statusline { 'StatusLine', { bg = p.base02 } }, { 'StatusLineNC', { fg = p.base02, bg = p.base05 } }, { 'WinBar', { bg = p.non } }, { 'WinBarNC', { bg = p.non } },
    --Error
    { 'ErrorMsg', { link = 'Error' } },
    --Markup
    { 'TODO', { fg = p.red } },
    { 'Conceal', { fg = p.blue } },
    { 'Error', { fg = p.red, bold = true } },
    { 'NonText', { link = 'Comment' } },
    --Float
    { 'FloatBorder', { fg = p.blue } },
    { 'FloatNormal', { link = 'Normal' } },
    { 'FloatShadow', { bg = p.base06 } },
    --Fold
    { 'Folded', { fg = p.bg, bold = true } },
    { 'FoldColumn', { link = 'SignColumn' } },
    --Spell
    { 'SpellBad', { fg = p.red } },
    { 'SpellCap', { undercurl = true, fg = p.red } },
    { 'SpellRare', { undercurl = true, sp = p.n_violet } },
    { 'SpellLocal', { undercurl = true } },
    --Msg
    { 'WarningMsg', { fg = p.red } },
    { 'MoreMsg', { fg = p.green } },
    --Internal
    { 'NvimInternalError', { fg = p.red } },
    { 'Directory', { fg = p.blue } },
    --------------------------------------------------------
    ---
    ---@Langauge Relate
    ---@Identifier
    { 'Identifier', { fg = p.blue } },
    -- various variable names
    { '@variable', { fg = p.fg } },
    --built-in variable names (e.g. `this`)
    { '@variable.builtin', { fg = p.orange } },
    { 'Constant', { fg = p.orange } },
    { '@constant.builtin', { link = 'Constant' } },
    -- constants defined by the preprocessor
    { '@constant.macro', {} },
    --modules or namespaces
    { '@namespace', { fg = p.cyan } },
    --symbols or atoms
    -- ['@symbol'] = {},
    --------------------------------------------------------
    ---@Keywords
    { 'Keyword', { fg = p.green } },
    { '@keyword.function', { link = 'Keyword' } },
    { '@keyword.return', { link = 'Keyword' } },
    { '@keyword.operator', { link = 'Operator' } },
    --if else
    { 'Conditional', { link = 'Keyword' } },
    --for while
    { 'Repeat', { link = 'Conditional' } },

    { 'Debug', { fg = p.orange } },
    { 'Label', { fg = p.purple } },
    { 'PreProc', { fg = p.purple } },
    { 'Include', { link = 'PreProc' } },
    { 'Exception', { fg = p.n_violet } },
    { 'Statement', { fg = p.purple } },
    { 'SpecialKey', { fg = p.orange } },
    { 'Special', { fg = p.orange } },
    --------------------------------------------------------
    ---@Types
    { 'Type', { fg = p.cyan } },
    { '@type.builtin', { link = 'Type' } },
    --type definitions (e.g. `typedef` in C)
    { '@type.definition', { link = 'Type' } },
    --type qualifiers (e.g. `const`)
    { '@type.qualifier', { link = 'KeyWord' } },
    --modifiers that affect storage in memory or life-time like C `static`
    { '@storageclass', { link = 'Keyword' } },
    { '@field', { fg = p.teal } },
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
    -- { '@constructor', { fg = p.n_orange } },
    { '@parameter', { link = '@variable' } },
    --------------------------------------------------------
    ---@Literals
    { 'String', { fg = p.yellow } },
    { 'Number', { fg = p.purple } },
    { 'Float', { link = 'Number' } },
    { 'Boolean', { link = 'Constant' } },
    --
    { 'Define', { link = 'PreProc' } },
    { 'Operator', { fg = p.fg_dim } },
    { 'Comment', { fg = p.fg_alt } },
    --------------------------------------------------------
    ---@punctuation
    { '@punctuation.bracket', { fg = p.fg_dim } },
    { '@punctuation.delimiter', { fg = p.fg_dim } },
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
    ---@Markdown
    { '@text.reference.markdown_inline', { fg = p.blue } },
    ---@Diff
    { 'DiffAdd', { fg = p.green } },
    { 'DiffChange', { fg = p.blue } },
    { 'DiffDelete', { fg = p.orange } },
    { 'DiffText', { fg = p.orange } },
    --------------------------------------------------------
    ---@Diagnostic
    { 'DiagnosticError', { link = 'Error' } },
    { 'DiagnosticWarn', { fg = p.yellow } },
    { 'DiagnosticInfo', { fg = p.blue } },
    { 'DiagnosticHint', { fg = p.cyan } },
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
    { 'DashboardHeader', { fg = p.green } },
    { 'DashboardFooter', { link = 'Comment' } },
    { 'DashboardProjectTitle', { fg = p.yellow, bold = true } },
    { 'DashboardProjectTitleIcon', { fg = p.violet } },
    { 'DashboardProjectIcon', { fg = p.blue } },
    { 'DashboardMruTitle', { link = 'DashboardProjectTitle' } },
    { 'DashboardMruIcon', { link = 'DashboardProjectTitleIcon' } },
    { 'DashboardFiles', { fg = p.fg_alt } },
    { 'DashboardShortCut', { link = 'Comment' } },
    { 'DashboardShortCutIcon', { link = '@field' } },
    --Telescope
    { 'TelescopePromptBorder', { bg = p.bg_alt, fg = p.fg_alt } },
    { 'TelescopePromptNormal', { bg = p.bg_alt, fg = p.orange } },
    { 'TelescopeResultsBorder', { bg = p.bg_alt, fg = p.fg_alt } },
    { 'TelescopePreviewBorder', { bg = p.bg_alt, fg = p.fg_alt } },
    { 'TelescopeResultsNormal', { fg = p.fg } },
    { 'TelescopeSelectionCaret', { fg = p.yellow } },
    { 'TelescopeMatching', { fg = p.yellow } },
    --CursorWord
    { 'CursorWord', { bg = p.bg_alt } },
    { 'IndentLine', { link = 'LineNr' } },
    --Lspsaga
    { 'SagaVariable', { fg = p.green } },
  }

  vim.cmd.hi('clear')
  opt.background = 'dark'
  opt.termguicolors = true
  g.colors_name = 'epic'
  for _, v in ipairs(groups) do
    api.nvim_set_hl(0, v[1], v[2])
  end
end

colorscheme()
