local platonic = {
  bg0 = '#282c34';
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

function platonic.terminal_color()
  vim.g.terminal_color_0 = platonic.bg0
  vim.g.terminal_color_1 = platonic.red
  vim.g.terminal_color_2 = platonic.green
  vim.g.terminal_color_3 = platonic.yellow
  vim.g.terminal_color_4 = platonic.blue
  vim.g.terminal_color_5 = platonic.purple
  vim.g.terminal_color_6 = platonic.cyan
  vim.g.terminal_color_7 = platonic.bg4
  vim.g.terminal_color_8 = platonic.grey0
  vim.g.terminal_color_9 = platonic.red
  vim.g.terminal_color_10 = platonic.green
  vim.g.terminal_color_11 = platonic.yellow
  vim.g.terminal_color_12 = platonic.blue
  vim.g.terminal_color_13 = platonic.purple
  vim.g.terminal_color_14 = platonic.cyan
  vim.g.terminal_color_15 = platonic.fg0
end

function platonic.highlight(group, color)
    local style = color.style and 'gui=' .. color.style or 'gui=NONE'
    local fg = color.fg and 'guifg=' .. color.fg or 'guifg=NONE'
    local bg = color.bg and 'guibg=' .. color.bg or 'guibg=NONE'
    vim.api.nvim_command('highlight ' .. group .. ' ' .. style .. ' ' .. fg ..
                             ' ' .. bg)
end


function platonic.load_syntax()
  local syntax = {
    Normal = {fg = platonic.fg0,bg=platonic.bg0};
    Terminal = {fg = platonic.fg0,bg=platonic.bg0};
    ToolbarLine = {fg = platonic.fg1,bg=platonic.bg3};
    SignColumn = {fg=platonic.fg0,bg=platonic.bg0};
    FoldColumn = {fg=platonic.grey0,bg=platonic.black};
    VertSplit = {fg=platonic.black,bg=platonic.bg0};
    Folded = {fg=platonic.grey1,bg=platonic.bg2};
    EndOfBuffer = {fg=platonic.bg0,bg=platonic.none};
    IncSearch = {fg=platonic.bg1,bg=platonic.orange,style=platonic.none};
    Search = {fg=platonic.bg0,bg=platonic.green};
    ColorColumn = {fg=platonic.none,bg=platonic.bg1};
    Conceal = {fg=platonic.grey1,bg=platonic.none};
    Cursor = {fg=platonic.none,bg=platonic.none,style='reverse'};
    vCursor = {fg=platonic.none,bg=platonic.none,style='reverse'};
    iCursor = {fg=platonic.none,bg=platonic.none,style='reverse'};
    lCursor = {fg=platonic.none,bg=platonic.none,style='reverse'};
    CursorIM = {fg=platonic.none,bg=platonic.none,style='reverse'};
    CursorColumn = {fg=platonic.none,bg=platonic.bg1};
    CursorLine = {fg=platonic.none,bg=platonic.bg1};
    LineNr = {fg=platonic.grey0};
    CursorLineNr = {fg=platonic.fg1};
    DiffAdd = {fg=platonic.black,bg=platonic.green};
    DiffChange = {fg=platonic.black,bg=platonic.yellow};
    DiffDelete = {fg=platonic.black,bg=platonic.red};
    DiffText = {fg=platonic.black,bg=platonic.fg0};
    Directory = {fg=platonic.bg4,bg=platonic.none};
    ErrorMsg = {fg=platonic.red,bg=platonic.none,style='bold'};
    WarningMsg = {fg=platonic.yellow,bg=platonic.none,style='bold'};
    ModeMsg = {fg=platonic.fg0,bg=platonic.none,style='bold'};
    MatchParen = {fg=platonic.none,bg=platonic.bg3};
    NonText = {fg=platonic.bg4};
    Whitespace = {fg=platonic.bg4};
    SpecialKey = {fg=platonic.bg4};
    Pmenu = {fg=platonic.fg1,bg=platonic.bg1};
    PmenuSel = {fg=platonic.bg3,bg=platonic.blue};
    PmenuSbar = {fg=platonic.none,bg=platonic.blue};
    PmenuThumb = {fg=platonic.none,bg=platonic.operator};
    WildMenu = {fg=platonic.bg3,bg=platonic.green};
    Question = {fg=platonic.yellow};
    NormalFloat = {fg=platonic.fg1,bg=platonic.bg1};
    TabLineFill = {style=platonic.none};
    StatusLine = {fg=platonic.fg1,bg=platonic.none,style=platonic.none};
    StatusLineNC = {fg=platonic.grey1,bg=platonic.none,style=platonic.none};
    SpellBad = {fg=platonic.red,bg=platonic.none,style='undercurl'};
    SpellCap = {fg=platonic.blue,bg=platonic.none,style='undercurl'};
    SpellLocal = {fg=platonic.cyan,bg=platonic.none,style='undercurl'};
    SpellRare = {fg=platonic.purple,bg=platonic.none,style = 'undercurl'};
    Visual = {fg=platonic.black,bg=platonic.operator,style='reverse'};
    VisualNOS = {fg=platonic.black,bg=platonic.operator,style='reverse'};
    QuickFixLine = {fg=platonic.purple,style='bold'};
    Debug = {fg=platonic.orange};
    debugBreakpoint = {fg=platonic.bg0,bg=platonic.red};
    ToolbarButton = {fg=platonic.bg0,bg=platonic.grey2};

    Boolean = {fg=platonic.orange};
    Number = {fg=platonic.purple};
    Float = {fg=platonic.purple};
    PreProc = {fg=platonic.purple};
    PreCondit = {fg=platonic.purple};
    Include = {fg=platonic.purple};
    Define = {fg=platonic.purple};
    Conditional = {fg=platonic.purple};
    Repeat = {fg=platonic.purple};
    Keyword = {fg=platonic.red};
    Typedef = {fg=platonic.red};
    Exception = {fg=platonic.red};
    Statement = {fg=platonic.red};
    Error = {fg=platonic.red};
    StorageClass = {fg=platonic.orange};
    Tag = {fg=platonic.orange};
    Label = {fg=platonic.orange};
    Structure = {fg=platonic.orange};
    Operator = {fg=platonic.operator};
    Title = {fg=platonic.orange,style='bold'};
    Special = {fg=platonic.yellow};
    SpecialChar = {fg=platonic.yellow};
    Type = {fg=platonic.yellow};
    Function = {fg=platonic.magenta,style='bold'};
    String = {fg=platonic.green};
    Character = {fg=platonic.green};
    Constant = {fg=platonic.cyan};
    Macro = {fg=platonic.cyan};
    Identifier = {fg=platonic.blue};

    Comment = {fg=platonic.grey1};
    SpecialComment = {fg=platonic.grey1};
    Todo = {fg=platonic.purple};
    Delimiter = {fg=platonic.fg0};
    Ignore = {fg=platonic.grey1};
    Underlined = {fg=platonic.none,style='underline'};

    TSFunction = {fg=platonic.yellow,style='bold'};
    TSMethod = {fg=platonic.yellow,style='bold'};
    TSKeywordFunction = {fg=platonic.blue};
    TSProperty = {fg=platonic.cyan};
    TSType = {fg=platonic.magenta};
    TSPunctBracket = {fg=platonic.bracket};


    typescriptImport = {fg=platonic.purple};
    typescriptAssign = {fg=platonic.operator};
    typescriptBraces = {fg=platonic.operator};
    typescriptParens = {fg=platonic.operator};
    typescriptExport = {fg=platonic.red};
    typescriptVariable = {fg=platonic.orange};
    typescriptDestructureVariable = {fg=platonic.fg_cyan};
    jsxComponentName = {fg=platonic.blue};

    vimCommentTitle = {fg=platonic.grey1,style='bold'};
    vimLet = {fg=platonic.orange};
    vimVar = {fg=platonic.cyan};
    vimFunction = {fg=platonic.magenta,style='bold'};
    vimIsCommand = {fg=platonic.fg0};
    vimCommand = {fg=platonic.blue};
    vimNotFunc = {fg=platonic.purple,style='bold'};
    vimUserFunc = {fg=platonic.yellow,style='bold'};
    vimFuncName= {fg=platonic.yellow,style='bold'};

    VistaBracket = {fg=platonic.grey1};
    VistaChildrenNr = {fg=platonic.orange};
    VistaKind = {fg=platonic.purpl};
    VistaScope = {fg=platonic.red};
    VistaScopeKind = {fg=platonic.blue};
    VistaTag = {fg=platonic.green,style='bold'};
    VistaPrefix = {fg=platonic.grey1};
    VistaColon = {fg=platonic.green};
    VistaIcon = {fg=platonic.yellow};
    VistaLineNr = {fg=platonic.fg0};

    GitGutterAdd = {fg=platonic.green};
    GitGutterChange = {fg=platonic.blue};
    GitGutterDelete = {fg=platonic.red};
    GitGutterChangeDelete = {fg=platonic.purple};

    SignifySignAdd = {fg=platonic.green};
    SignifySignChange = {fg=platonic.blue};
    SignifySignDelete = {fg=platonic.red};

    Floaterm = {fg=platonic.none,bg=platonic.bg0};
    FloatermBorder = {fg=platonic.blue,bg=platonic.none};

    dbui_tables = {fg=platonic.blue};

    DefxIconsParentDirectory = {fg=platonic.orange};
    Defx_filename_directory = {fg=platonic.blue};
    Defx_filename_root = {fg=platonic.red};

    DashboardShortCut = {fg=platonic.red,style='bold'};
    DashboardHeader = {fg=platonic.blue,style='bold'};
    DashboardFooter = {fg=platonic.purple,style='bold'};

    LspDiagnosticsError = {fg=platonic.red};
    LspDiagnosticsWarning = {fg=platonic.yellow};
    LspDiagnosticsInformation = {fg=platonic.blue};
    LspDiagnosticsHint = {fg=platonic.cyan};

    CursorWord0 = {bg=platonic.fg3};
    CursorWord1 = {bg=platonic.fg3};

  }
  return syntax
end

function platonic.colorscheme()
  vim.g.colors_name = 'platonic'
  vim.o.background = 'dark'
  if vim.o.termguicolors ~= true then
    vim.o.termguicolors = true
  end
  platonic.terminal_color()
  for group,colors in pairs(platonic.load_syntax()) do
    platonic.highlight(group,colors)
  end
end

return platonic
