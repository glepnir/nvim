local g, api, opt = vim.g, vim.api, vim.opt
--HSV S: %80 V: 80%-90%

local function palette()
  return {
    bg = '#1D1D1D',
    bg_dim = '#303030',
    fg = '#cccccc',
    fg_dim = '#989898',
    fg_alt = '#75715E',
    orange = '#FFA348',
    green = '#b1cc29',
    --H 190 S 60 V 90
    cyan = '#5ccfe6',
    blue = '#59c2ff',
  }
end

local function in_vim(groups, p)
  -- g.terminal_color_0 = p.base05
  -- g.terminal_color_1 = p.red
  -- g.terminal_color_2 = p.green
  -- g.terminal_color_3 = p.yellow
  -- g.terminal_color_4 = p.blue
  -- g.terminal_color_5 = p.magenta
  -- g.terminal_color_6 = p.cyan
  -- g.terminal_color_7 = p.base3
  -- g.terminal_color_8 = p.base01
  -- g.terminal_color_9 = p.orange
  -- g.terminal_color_10 = p.base00
  -- g.terminal_color_11 = p.base0
  -- g.terminal_color_12 = p.base1
  -- g.terminal_color_13 = p.violet
  -- g.terminal_color_14 = p.base2
  -- g.terminal_color_15 = p.base3
end

local function colorscheme()
  local p = palette()

  local groups = {
    --Neovim Relate
    { 'Normal', { fg = p.fg, bg = p.bg } },
    --signcolumn
    { 'SignColumn', { bg = p.bg } },
    --buffer
    { 'LineNr', { fg = p.bg_dim } },
    { 'EndOfBuffer', { bg = p.non, fg = p.bg } },
    { 'Search', { fg = p.yellow_cooler, reverse = true } },
    { 'Visual', { bg = p.base02 } },
    { 'ColorColumn', { bg = p.base02 } },
    { 'Whitespace', { fg = p.base02 } },
    --window
    { 'VertSplit', { fg = p.base02 } },
    { 'Title', { fg = p.n_orange, bold = true } },
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
    { 'WildMenu', { link = 'pmenu' } }, --statusline { 'StatusLine', { bg = p.base02 } }, { 'StatusLineNC', { fg = p.base02, bg = p.base05 } }, { 'WinBar', { bg = p.non } }, { 'WinBarNC', { bg = p.non } },
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
    { 'SpellRare', { undercurl = true, sp = p.n_violet } },
    { 'SpellLocal', { undercurl = true } },
    --Msg
    { 'WarningMsg', { fg = p.magenta } },
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
    { '@variable', { fg = p.base0 } },
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
    { 'Keyword', { fg = p.magenta_cooler } },
    { '@keyword.function', { link = 'Keyword' } },
    { '@keyword.return', { link = 'Keyword' } },
    { '@keyword.operator', { link = 'Operator' } },
    --if else
    { 'Conditional', { link = 'Keyword' } },
    --for while
    { 'Repeat', { link = 'Conditional' } },

    { 'Debug', { fg = p.orange } },
    { 'Label', { fg = p.magenta_cooler } },
    { 'PreProc', { fg = p.magenta_cooler } },
    { 'Include', { link = 'PreProc' } },
    { 'Exception', { fg = p.n_violet } },
    { 'Statement', { fg = p.magenta_cooler } },
    { 'SpecialKey', { fg = p.orange } },
    { 'Special', { fg = p.orange } },
    --------------------------------------------------------
    ---@Types
    { 'Type', { fg = p.green_cooler } },
    { '@type.builtin', { link = 'Type' } },
    --type definitions (e.g. `typedef` in C)
    { '@type.definition', { link = 'Type' } },
    --type qualifiers (e.g. `const`)
    { '@type.qualifier', { link = 'KeyWord' } },
    --modifiers that affect storage in memory or life-time like C `static`
    { '@storageclass', { link = 'Keyword' } },
    { '@field', { fg = p.yellow_warmer } },
    { '@property', { link = '@field' } },
    --------------------------------------------------------
    ---@Functions
    { 'Function', { fg = p.cyan } },
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
    { 'String', { fg = p.green } },
    { 'Number', { fg = p.pink } },
    { 'Float', { link = 'Number' } },
    { 'Boolean', { link = 'Constant' } },
    --
    { 'Define', { link = 'PreProc' } },
    { 'Operator', { fg = p.yellow_cooler } },
    { 'Comment', { fg = p.fg_alt } },
    --------------------------------------------------------
    ---@punctuation
    { '@punctuation.bracket', { fg = p.base00 } },
    { '@punctuation.delimiter', { link = 'Operator' } },
    --------------------------------------------------------
    ---@Tag
    { '@tag.html', { fg = p.n_orange } },
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
    { 'DashboardHeader', { fg = p.green } },
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
    { 'TelescopePromptNormal', { bg = p.base02, fg = p.orange } },
    { 'TelescopeResultsBorder', { bg = p.base02, fg = p.base02 } },
    { 'TelescopePreviewBorder', { bg = p.base02, fg = p.base02 } },
    { 'TelescopeResultsNormal', { fg = p.base0 } },
    { 'TelescopeSelectionCaret', { fg = p.yellow } },
    { 'TelescopeMatching', { fg = p.yellow } },
    --CursorWord
    { 'CursorWord', { bg = p.base02 } },
    { 'IndentLine', { link = 'LineNr' } },
    --Lspsaga
    { 'SagaWinbarVariable', { fg = p.green } },
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
