local bg_color = {
  dark = '#212127',
  medium = '#282c34'
}

local zephyr = {
  bg0 = bg_color["medium"];
  bg1 = '#343d46';
  bg2 = '#282828';
  bg3 = '#3c3836';
  bg4 = '#504945';
  fg0 = '#d4be98';
  fg1 = '#ddc7a1';
  fg3 = '#4f5b66';
  red = '#EC5f67';
  magenta = '#d16d9e';
  orange = '#e78a4e';
  yellow = '#d8a657';
  green = '#5faf5f';
  cyan = '#56b6c2';
  blue = '#4989c9';
  purple = '#ba8baf';
  black = '#000000';
  bg_red = '#ea6962';
  grey0 = '#7c6f64';
  grey1 = '#928374';
  grey2 = '#a89984';
  operator = '#b3deef';
  bracket = '#93a1a1';
  none = 'NONE';
}

function zephyr.terminal_color()
  vim.g.terminal_color_0 = zephyr.bg0
  vim.g.terminal_color_1 = zephyr.red
  vim.g.terminal_color_2 = zephyr.green
  vim.g.terminal_color_3 = zephyr.yellow
  vim.g.terminal_color_4 = zephyr.blue
  vim.g.terminal_color_5 = zephyr.purple
  vim.g.terminal_color_6 = zephyr.cyan
  vim.g.terminal_color_7 = zephyr.bg4
  vim.g.terminal_color_8 = zephyr.grey0
  vim.g.terminal_color_9 = zephyr.red
  vim.g.terminal_color_10 = zephyr.green
  vim.g.terminal_color_11 = zephyr.yellow
  vim.g.terminal_color_12 = zephyr.blue
  vim.g.terminal_color_13 = zephyr.purple
  vim.g.terminal_color_14 = zephyr.cyan
  vim.g.terminal_color_15 = zephyr.fg0
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
    Normal = {fg = zephyr.fg0,bg=zephyr.bg0};
    Terminal = {fg = zephyr.fg0,bg=zephyr.bg0};
    ToolbarLine = {fg = zephyr.fg1,bg=zephyr.bg3};
    SignColumn = {fg=zephyr.fg0,bg=zephyr.bg0};
    FoldColumn = {fg=zephyr.grey0,bg=zephyr.black};
    VertSplit = {fg=zephyr.black,bg=zephyr.bg0};
    Folded = {fg=zephyr.grey1,bg=zephyr.bg2};
    EndOfBuffer = {fg=zephyr.bg0,bg=zephyr.none};
    IncSearch = {fg=zephyr.bg1,bg=zephyr.orange,style=zephyr.none};
    Search = {fg=zephyr.bg0,bg=zephyr.green};
    ColorColumn = {fg=zephyr.none,bg=zephyr.bg1};
    Conceal = {fg=zephyr.grey1,bg=zephyr.none};
    Cursor = {fg=zephyr.none,bg=zephyr.none,style='reverse'};
    vCursor = {fg=zephyr.none,bg=zephyr.none,style='reverse'};
    iCursor = {fg=zephyr.none,bg=zephyr.none,style='reverse'};
    lCursor = {fg=zephyr.none,bg=zephyr.none,style='reverse'};
    CursorIM = {fg=zephyr.none,bg=zephyr.none,style='reverse'};
    CursorColumn = {fg=zephyr.none,bg=zephyr.bg1};
    CursorLine = {fg=zephyr.none,bg=zephyr.bg1};
    LineNr = {fg=zephyr.grey0};
    CursorLineNr = {fg=zephyr.fg1};
    DiffAdd = {fg=zephyr.black,bg=zephyr.green};
    DiffChange = {fg=zephyr.black,bg=zephyr.yellow};
    DiffDelete = {fg=zephyr.black,bg=zephyr.red};
    DiffText = {fg=zephyr.black,bg=zephyr.fg0};
    Directory = {fg=zephyr.bg4,bg=zephyr.none};
    ErrorMsg = {fg=zephyr.red,bg=zephyr.none,style='bold'};
    WarningMsg = {fg=zephyr.yellow,bg=zephyr.none,style='bold'};
    ModeMsg = {fg=zephyr.fg0,bg=zephyr.none,style='bold'};
    MatchParen = {fg=zephyr.none,bg=zephyr.bg3};
    NonText = {fg=zephyr.bg4};
    Whitespace = {fg=zephyr.bg4};
    SpecialKey = {fg=zephyr.bg4};
    Pmenu = {fg=zephyr.fg1,bg=zephyr.bg1};
    PmenuSel = {fg=zephyr.bg3,bg=zephyr.blue};
    PmenuSbar = {fg=zephyr.none,bg=zephyr.blue};
    PmenuThumb = {fg=zephyr.none,bg=zephyr.operator};
    WildMenu = {fg=zephyr.bg3,bg=zephyr.green};
    Question = {fg=zephyr.yellow};
    NormalFloat = {fg=zephyr.fg1,bg=zephyr.bg1};
    TabLineFill = {style=zephyr.none};
    StatusLine = {fg=zephyr.fg1,bg=zephyr.none,style=zephyr.none};
    StatusLineNC = {fg=zephyr.grey1,bg=zephyr.none,style=zephyr.none};
    SpellBad = {fg=zephyr.red,bg=zephyr.none,style='undercurl'};
    SpellCap = {fg=zephyr.blue,bg=zephyr.none,style='undercurl'};
    SpellLocal = {fg=zephyr.cyan,bg=zephyr.none,style='undercurl'};
    SpellRare = {fg=zephyr.purple,bg=zephyr.none,style = 'undercurl'};
    Visual = {fg=zephyr.black,bg=zephyr.operator};
    VisualNOS = {fg=zephyr.black,bg=zephyr.operator};
    QuickFixLine = {fg=zephyr.purple,style='bold'};
    Debug = {fg=zephyr.orange};
    debugBreakpoint = {fg=zephyr.bg0,bg=zephyr.red};
    ToolbarButton = {fg=zephyr.bg0,bg=zephyr.grey2};

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
    Operator = {fg=zephyr.operator};
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

    Comment = {fg=zephyr.grey1};
    SpecialComment = {fg=zephyr.grey1};
    Todo = {fg=zephyr.purple};
    Delimiter = {fg=zephyr.fg0};
    Ignore = {fg=zephyr.grey1};
    Underlined = {fg=zephyr.none,style='underline'};

    TSFunction = {fg=zephyr.yellow,style='bold'};
    TSMethod = {fg=zephyr.yellow,style='bold'};
    TSKeywordFunction = {fg=zephyr.blue};
    TSProperty = {fg=zephyr.cyan};
    TSType = {fg=zephyr.magenta};
    TSPunctBracket = {fg=zephyr.bracket};

    typescriptImport = {fg=zephyr.purple};
    typescriptAssign = {fg=zephyr.operator};
    typescriptBraces = {fg=zephyr.bracket};
    typescriptParens = {fg=zephyr.bracket};
    typescriptExport = {fg=zephyr.red};
    typescriptVariable = {fg=zephyr.orange};
    typescriptDestructureVariable = {fg=zephyr.fg_cyan};
    jsxComponentName = {fg=zephyr.blue};

    vimCommentTitle = {fg=zephyr.grey1,style='bold'};
    vimLet = {fg=zephyr.orange};
    vimVar = {fg=zephyr.cyan};
    vimFunction = {fg=zephyr.magenta,style='bold'};
    vimIsCommand = {fg=zephyr.fg0};
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
    diffLine    = {fg = zephyr.grey1};
    diffIndexLine = {fg = zephyr.purple};

    gitcommitSummary = {fg = zephyr.red};
    gitcommitUntracked = {fg = zephyr.grey1};
    gitcommitDiscarded = {fg = zephyr.grey1};
    gitcommitSelected = { fg=zephyr.grey1};
    gitcommitUnmerged = { fg=zephyr.grey1};
    gitcommitOnBranch = { fg=zephyr.grey1};
    gitcommitArrow  = {fg = zephyr.grey1};
    gitcommitFile  = {fg = zephyr.green};

    VistaBracket = {fg=zephyr.grey1};
    VistaChildrenNr = {fg=zephyr.orange};
    VistaKind = {fg=zephyr.purpl};
    VistaScope = {fg=zephyr.red};
    VistaScopeKind = {fg=zephyr.blue};
    VistaTag = {fg=zephyr.green,style='bold'};
    VistaPrefix = {fg=zephyr.grey1};
    VistaColon = {fg=zephyr.green};
    VistaIcon = {fg=zephyr.yellow};
    VistaLineNr = {fg=zephyr.fg0};

    GitGutterAdd = {fg=zephyr.green};
    GitGutterChange = {fg=zephyr.blue};
    GitGutterDelete = {fg=zephyr.red};
    GitGutterChangeDelete = {fg=zephyr.purple};

    SignifySignAdd = {fg=zephyr.green};
    SignifySignChange = {fg=zephyr.blue};
    SignifySignDelete = {fg=zephyr.red};

    Floaterm = {fg=zephyr.none,bg=zephyr.bg0};
    FloatermBorder = {fg=zephyr.blue,bg=zephyr.none};

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

    CursorWord0 = {bg=zephyr.fg3};
    CursorWord1 = {bg=zephyr.fg3};

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

  if vim.g.zephyr_background == 'dark' then
    zephyr.bg0 = bg_color["dark"]
  end

  zephyr.terminal_color()
  for group,colors in pairs(zephyr.load_syntax()) do
    zephyr.highlight(group,colors)
  end
end

return zephyr
