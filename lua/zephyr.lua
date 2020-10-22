
local zephyr = {
  base0      = '#1B2229';
  base1      = '#1c1f24';
  base2      = '#202328';
  base3      = '#23272e';
  base4      = '#3f444a';
  base5      = '#5B6268';
  base6      = '#73797e';
  base7      = '#9ca0a4';
  base8      = '#b1b1b1';

  bg = '#282c34';
  bg1 = '#504945';
  bg_popup = '#3E4556';
  bg_highlight  = '#2E323C';
  bg_visual = '#b3deef';

  fg = '#bbc2cf';
  fg_alt  = '#5B6268';

  red = '#EC5f67';
  magenta = '#d16d9e';
  orange = '#da8548';
  yellow = '#d8a657';
  green = '#98be65';
  cyan = '#56b6c2';
  blue = '#51afef';
  purple = '#ba8baf';
  teal = '#1abc9c';
  grey = '#928374';
  brown = '#666660';
  black = '#000000';

  bracket = '#93a1a1';
  currsor_bg = '#4f5b66';
  none = 'NONE';
}

function zephyr.terminal_color()
  vim.g.terminal_color_0 = zephyr.bg
  vim.g.terminal_color_1 = zephyr.red
  vim.g.terminal_color_2 = zephyr.green
  vim.g.terminal_color_3 = zephyr.yellow
  vim.g.terminal_color_4 = zephyr.blue
  vim.g.terminal_color_5 = zephyr.purple
  vim.g.terminal_color_6 = zephyr.cyan
  vim.g.terminal_color_7 = zephyr.bg1
  vim.g.terminal_color_8 = zephyr.brown
  vim.g.terminal_color_9 = zephyr.red
  vim.g.terminal_color_10 = zephyr.green
  vim.g.terminal_color_11 = zephyr.yellow
  vim.g.terminal_color_12 = zephyr.blue
  vim.g.terminal_color_13 = zephyr.purple
  vim.g.terminal_color_14 = zephyr.cyan
  vim.g.terminal_color_15 = zephyr.fg
end

function zephyr.highlight(group, color)
    local style = color.style and 'gui=' .. color.style or 'gui=NONE'
    local fg = color.fg and 'guifg=' .. color.fg or 'guifg=NONE'
    local bg = color.bg and 'guibg=' .. color.bg or 'guibg=NONE'
    vim.api.nvim_command('highlight ' .. group .. ' ' .. style .. ' ' .. fg ..
                             ' ' .. bg)
end


function zephyr.load_syntax()
  local syntax = {
    Normal = {fg = zephyr.fg,bg=zephyr.bg};
    Terminal = {fg = zephyr.fg,bg=zephyr.bg};
    SignColumn = {fg=zephyr.fg,bg=zephyr.bg};
    FoldColumn = {fg=zephyr.fg_alt,bg=zephyr.black};
    VertSplit = {fg=zephyr.black,bg=zephyr.bg};
    Folded = {fg=zephyr.grey,bg=zephyr.bg_highlight};
    EndOfBuffer = {fg=zephyr.bg,bg=zephyr.none};
    IncSearch = {fg=zephyr.bg1,bg=zephyr.orange,style=zephyr.none};
    Search = {fg=zephyr.bg,bg=zephyr.green};
    ColorColumn = {fg=zephyr.none,bg=zephyr.bg_highlight};
    Conceal = {fg=zephyr.grey,bg=zephyr.none};
    Cursor = {fg=zephyr.none,bg=zephyr.none,style='reverse'};
    vCursor = {fg=zephyr.none,bg=zephyr.none,style='reverse'};
    iCursor = {fg=zephyr.none,bg=zephyr.none,style='reverse'};
    lCursor = {fg=zephyr.none,bg=zephyr.none,style='reverse'};
    CursorIM = {fg=zephyr.none,bg=zephyr.none,style='reverse'};
    CursorColumn = {fg=zephyr.none,bg=zephyr.bg_highlight};
    CursorLine = {fg=zephyr.none,bg=zephyr.bg_highlight};
    LineNr = {fg=zephyr.base4};
    CursorLineNr = {fg=zephyr.blue};
    DiffAdd = {fg=zephyr.black,bg=zephyr.green};
    DiffChange = {fg=zephyr.black,bg=zephyr.yellow};
    DiffDelete = {fg=zephyr.black,bg=zephyr.red};
    DiffText = {fg=zephyr.black,bg=zephyr.fg};
    Directory = {fg=zephyr.bg1,bg=zephyr.none};
    ErrorMsg = {fg=zephyr.red,bg=zephyr.none,style='bold'};
    WarningMsg = {fg=zephyr.yellow,bg=zephyr.none,style='bold'};
    ModeMsg = {fg=zephyr.fg,bg=zephyr.none,style='bold'};
    MatchParen = {fg=zephyr.red,bg=zephyr.none};
    NonText = {fg=zephyr.bg1};
    Whitespace = {fg=zephyr.bg1};
    SpecialKey = {fg=zephyr.bg1};
    Pmenu = {fg=zephyr.fg,bg=zephyr.bg_popup};
    PmenuSel = {fg=zephyr.base0,bg=zephyr.blue};
    PmenuSelBold = {fg=zephyr.base0,g=zephyr.blue};
    PmenuSbar = {fg=zephyr.none,bg=zephyr.blue};
    PmenuThumb = {fg=zephyr.brown,bg=zephyr.brown};
    WildMenu = {fg=zephyr.fg,bg=zephyr.green};
    Question = {fg=zephyr.yellow};
    NormalFloat = {fg=zephyr.base8,bg=zephyr.bg_highlight};
    TabLineFill = {style=zephyr.none};
    StatusLine = {fg=zephyr.base8,bg=zephyr.none,style=zephyr.none};
    StatusLineNC = {fg=zephyr.grey,bg=zephyr.none,style=zephyr.none};
    SpellBad = {fg=zephyr.red,bg=zephyr.none,style='undercurl'};
    SpellCap = {fg=zephyr.blue,bg=zephyr.none,style='undercurl'};
    SpellLocal = {fg=zephyr.cyan,bg=zephyr.none,style='undercurl'};
    SpellRare = {fg=zephyr.purple,bg=zephyr.none,style = 'undercurl'};
    Visual = {fg=zephyr.black,bg=zephyr.bg_visual};
    VisualNOS = {fg=zephyr.black,bg=zephyr.bg_visual};
    QuickFixLine = {fg=zephyr.purple,style='bold'};
    Debug = {fg=zephyr.orange};
    debugBreakpoint = {fg=zephyr.bg,bg=zephyr.red};

    Boolean = {fg=zephyr.orange};
    Number = {fg=zephyr.purple};
    Float = {fg=zephyr.purple};
    PreProc = {fg=zephyr.purple};
    PreCondit = {fg=zephyr.purple};
    Include = {fg=zephyr.purple};
    Define = {fg=zephyr.purple};
    Conditional = {fg=zephyr.purple};
    Repeat = {fg=zephyr.purple};
    Keyword = {fg=zephyr.red};
    Typedef = {fg=zephyr.red};
    Exception = {fg=zephyr.red};
    Statement = {fg=zephyr.red};
    Error = {fg=zephyr.red};
    StorageClass = {fg=zephyr.orange};
    Tag = {fg=zephyr.orange};
    Label = {fg=zephyr.orange};
    Structure = {fg=zephyr.orange};
    Operator = {fg=zephyr.teal};
    Title = {fg=zephyr.orange,style='bold'};
    Special = {fg=zephyr.yellow};
    SpecialChar = {fg=zephyr.yellow};
    Type = {fg=zephyr.yellow};
    Function = {fg=zephyr.magenta,style='bold'};
    String = {fg=zephyr.green};
    Character = {fg=zephyr.green};
    Constant = {fg=zephyr.cyan};
    Macro = {fg=zephyr.cyan};
    Identifier = {fg=zephyr.blue};

    Comment = {fg=zephyr.base6};
    SpecialComment = {fg=zephyr.grey};
    Todo = {fg=zephyr.purple};
    Delimiter = {fg=zephyr.fg};
    Ignore = {fg=zephyr.grey};
    Underlined = {fg=zephyr.none,style='underline'};

    TSFunction = {fg=zephyr.yellow,style='bold'};
    TSMethod = {fg=zephyr.yellow,style='bold'};
    TSKeywordFunction = {fg=zephyr.blue};
    TSProperty = {fg=zephyr.cyan};
    TSType = {fg=zephyr.magenta};
    TSPunctBracket = {fg=zephyr.bracket};

    typescriptImport = {fg=zephyr.purple};
    typescriptAssign = {fg=zephyr.teal};
    typescriptBraces = {fg=zephyr.bracket};
    typescriptParens = {fg=zephyr.bracket};
    typescriptExport = {fg=zephyr.red};
    typescriptVariable = {fg=zephyr.orange};
    typescriptDestructureVariable = {fg=zephyr.fg_cyan};
    jsxComponentName = {fg=zephyr.blue};

    vimCommentTitle = {fg=zephyr.grey,style='bold'};
    vimLet = {fg=zephyr.orange};
    vimVar = {fg=zephyr.cyan};
    vimFunction = {fg=zephyr.magenta,style='bold'};
    vimIsCommand = {fg=zephyr.fg};
    vimCommand = {fg=zephyr.blue};
    vimNotFunc = {fg=zephyr.purple,style='bold'};
    vimUserFunc = {fg=zephyr.yellow,style='bold'};
    vimFuncName= {fg=zephyr.yellow,style='bold'};

    diffAdded = {fg = zephyr.green};
    diffRemoved = {fg =zephyr.red};
    diffChanged = {fg = zephyr.blue};
    diffOldFile = {fg = zephyr.yellow};
    diffNewFile = {fg = zephyr.orange};
    diffFile    = {fg = zephyr.aqua};
    diffLine    = {fg = zephyr.grey};
    diffIndexLine = {fg = zephyr.purple};

    gitcommitSummary = {fg = zephyr.red};
    gitcommitUntracked = {fg = zephyr.grey};
    gitcommitDiscarded = {fg = zephyr.grey};
    gitcommitSelected = { fg=zephyr.grey};
    gitcommitUnmerged = { fg=zephyr.grey};
    gitcommitOnBranch = { fg=zephyr.grey};
    gitcommitArrow  = {fg = zephyr.grey};
    gitcommitFile  = {fg = zephyr.green};

    VistaBracket = {fg=zephyr.grey};
    VistaChildrenNr = {fg=zephyr.orange};
    VistaKind = {fg=zephyr.purpl};
    VistaScope = {fg=zephyr.red};
    VistaScopeKind = {fg=zephyr.blue};
    VistaTag = {fg=zephyr.green,style='bold'};
    VistaPrefix = {fg=zephyr.grey};
    VistaColon = {fg=zephyr.green};
    VistaIcon = {fg=zephyr.yellow};
    VistaLineNr = {fg=zephyr.fg};

    GitGutterAdd = {fg=zephyr.green};
    GitGutterChange = {fg=zephyr.blue};
    GitGutterDelete = {fg=zephyr.red};
    GitGutterChangeDelete = {fg=zephyr.purple};

    SignifySignAdd = {fg=zephyr.green};
    SignifySignChange = {fg=zephyr.blue};
    SignifySignDelete = {fg=zephyr.red};

    dbui_tables = {fg=zephyr.blue};

    DefxIconsParentDirectory = {fg=zephyr.orange};
    Defx_filename_directory = {fg=zephyr.blue};
    Defx_filename_root = {fg=zephyr.red};

    DashboardShortCut = {fg=zephyr.red,style='bold'};
    DashboardHeader = {fg=zephyr.blue,style='bold'};
    DashboardFooter = {fg=zephyr.purple,style='bold'};

    LspDiagnosticsError = {fg=zephyr.red};
    LspDiagnosticsWarning = {fg=zephyr.yellow};
    LspDiagnosticsInformation = {fg=zephyr.blue};
    LspDiagnosticsHint = {fg=zephyr.cyan};

    CursorWord0 = {bg=zephyr.currsor_bg};
    CursorWord1 = {bg=zephyr.currsor_bg};

    luaTreeFolderName = {fg=zephyr.blue};
    LuaTreeRootFolder = {fg=zephyr.red}
  }
  return syntax
end

function zephyr.colorscheme()
  vim.api.nvim_command('hi clear')
  if vim.fn.exists('syntax_on') then
    vim.api.nvim_command('syntax reset')
  end
  -- vim.g.colors_name = 'zephyr'
  vim.o.background = 'dark'
  vim.o.termguicolors = true

  zephyr.terminal_color()
  for group,colors in pairs(zephyr.load_syntax()) do
    zephyr.highlight(group,colors)
  end
end

zephyr.colorscheme()
