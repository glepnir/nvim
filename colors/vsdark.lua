-- ═══════════════════════════════════════════════════════════════════════════
-- VS Code 2026 Dark — Neovim Port
-- ═══════════════════════════════════════════════════════════════════════════
--
-- Inheritance chain:
--   2026-dark.json  →  dark_modern.json  →  dark_plus.json  →  dark_vs.json
--
-- UI colors:    from 2026-dark.json   (deep bg #121314, neutral borders)
-- Syntax:       from dark_vs + dark_plus tokenColors + semantic highlighting
-- Verified:     against screenshot RGB values + web inspector

vim.cmd('hi clear')
if vim.fn.exists('syntax_on') then
  vim.cmd('syntax reset')
end

vim.g.colors_name = 'vscode-2026-dark'
vim.o.background = 'dark'

-- ═══════════════════════════════════════════════════════════════════════════
-- PALETTE
-- ═══════════════════════════════════════════════════════════════════════════
local c = {
  -- ─── Surface (2026-dark.json) ──────────────────────────────────────────
  -- bg = '#121314', -- editor.background
  bg = '#1f1f1f',
  bg_sidebar = '#191A1B', -- sideBar/panel/terminal background
  bg_float = '#202122', -- editorWidget/suggest/hover background
  bg_cursorline = '#242526', -- editor.lineHighlightBackground
  bg_menu_sel = '#2C2D2E', -- list.inactiveSelectionBackground
  bg_selection = '#276782', -- editor.selectionBackground
  border = '#2A2B2C', -- widget.border / all borders
  border_input = '#333536', -- input.border

  -- ─── Foreground tiers ──────────────────────────────────────────────────
  fg = '#BBBEBF', -- editor.foreground (2026-dark.json)
  fg_ui = '#bfbfbf', -- foreground (UI elements)
  fg_emphasis = '#ededed', -- list.activeSelectionForeground
  fg_dim = '#8C8C8C', -- descriptionForeground / inactive
  fg_disabled = '#555555', -- disabledForeground
  fg_linenr = '#858889', -- editorLineNumber.foreground
  fg_linenr_act = '#BBBEBF', -- editorLineNumber.activeForeground
  fg_dark_modern = '#CCCCCC',

  -- ─── Accent ────────────────────────────────────────────────────────────
  accent = '#3994BC', -- focusBorder / badge / panelTitle.activeBorder

  -- ─── Syntax  (dark_vs.json + dark_plus.json) ──────────────────────────
  blue = '#569cd6', -- keyword, storage, constant.language, bool, tag
  light_blue = '#9cdcfe', -- parameter, property, attribute-name
  bright_blue = '#4fc1ff', -- variable.other.constant, enummember
  teal = '#4ec9b0', -- type, class, namespace, support.class
  green = '#6a9955', -- comment
  light_green = '#b5cea8', -- number (constant.numeric)
  yellow = '#dcdcaa', -- function name
  gold = '#d7ba7d', -- escape sequences, CSS selectors
  orange = '#ce9178', -- string
  red = '#d16969', -- regexp
  pink = '#c586c0', -- control flow keywords (if/return/using)
  gray = '#808080', -- tag brackets (punctuation.definition.tag)
  label_gray = '#c8c8c8', -- entity.name.label
  error_red = '#f44747', -- invalid

  -- ─── Diagnostics (2026-dark.json) ──────────────────────────────────────
  diag_error = '#f48771', -- errorForeground
  diag_warn = '#e5ba7d', -- list.warningForeground
  diag_info = '#3994BC', -- accent
  diag_hint = '#73c991', -- gitDecoration.addedResource

  -- ─── Git / Diff (2026-dark.json) ───────────────────────────────────────
  git_add = '#72C892', -- editorGutter.addedBackground
  git_change = '#e5ba7d', -- gitDecoration.modifiedResource
  git_delete = '#F28772', -- editorGutter.deletedBackground
  diff_add_bg = '#347d39', -- diffEditor.insertedLineBackground
  diff_del_bg = '#c93c37', -- diffEditor.removedLineBackground

  none = 'NONE',
}

-- ═══════════════════════════════════════════════════════════════════════════
-- HELPERS
-- ═══════════════════════════════════════════════════════════════════════════
local function h(group, opts)
  vim.api.nvim_set_hl(0, group, opts)
end

local function hex_to_rgb(hex)
  hex = hex:gsub('#', '')
  return {
    tonumber(hex:sub(1, 2), 16),
    tonumber(hex:sub(3, 4), 16),
    tonumber(hex:sub(5, 6), 16),
  }
end

local function rgb_to_hex(rgb)
  return string.format('#%02x%02x%02x', rgb[1], rgb[2], rgb[3])
end

local function blend(fg, t, target_bg)
  local a = hex_to_rgb(fg)
  local b = hex_to_rgb(target_bg or c.bg)
  return rgb_to_hex({
    math.floor(a[1] * (1 - t) + b[1] * t + 0.5),
    math.floor(a[2] * (1 - t) + b[2] * t + 0.5),
    math.floor(a[3] * (1 - t) + b[3] * t + 0.5),
  })
end

-- =============================================================================
-- 1. Core Editor Surface
-- =============================================================================
h('Normal', { fg = c.fg, bg = c.bg })
h('NormalNC', { fg = c.fg, bg = c.bg })
h('EndOfBuffer', { fg = c.bg })
h('CursorLine', { bg = c.bg_cursorline })
h('CursorColumn', { bg = c.bg_cursorline })
h('CursorLineNr', { fg = c.fg_linenr_act, bold = true })
h('LineNr', { fg = c.fg_linenr })
h('SignColumn', { fg = c.fg_linenr, bg = c.bg })
h('FoldColumn', { fg = c.fg_dim, bg = c.bg })
h('Folded', { fg = c.fg_dim, bg = c.bg_cursorline })
h('WinSeparator', { fg = c.border, bg = c.bg })
h('VertSplit', { fg = c.border, bg = c.bg })
h('ColorColumn', { bg = c.bg_cursorline })
h('Conceal', { fg = c.fg_dim })
h('Cursor', { fg = c.bg, bg = c.fg })
h('lCursor', { fg = c.bg, bg = c.fg })
h('CursorIM', { fg = c.bg, bg = c.fg })
h('TermCursor', { fg = c.bg, bg = c.fg })
h('TermCursorNC', { fg = c.bg, bg = c.fg_dim })

-- =============================================================================
-- 2. Visual & Search
-- =============================================================================
h('Visual', { bg = c.bg_selection })
h('VisualNOS', { bg = c.bg_selection })
h('Search', { fg = c.bg, bg = c.diag_warn })
h('IncSearch', { fg = c.bg, bg = c.yellow })
h('CurSearch', { fg = c.bg, bg = c.yellow })
h('Substitute', { fg = c.bg, bg = c.diag_error })

-- =============================================================================
-- 3. Syntax
-- =============================================================================

-- ─── Keywords ────────────────────────────────────────────────────────────
-- keyword.control (if/return/for/while/try/catch/using/namespace) → #C586C0
h('Keyword', { fg = c.pink })
h('Statement', { fg = c.pink })
h('Conditional', { fg = c.pink })
h('Repeat', { fg = c.pink })
h('Exception', { fg = c.pink })
h('Label', { fg = c.label_gray })

-- ─── Functions ───────────────────────────────────────────────────────────
-- entity.name.function → #DCDCAA
h('Function', { fg = c.yellow })

-- ─── Types ───────────────────────────────────────────────────────────────
-- support.class/type, entity.name.type → #4EC9B0
-- storage / storage.type → #569cd6
h('Type', { fg = c.teal })
h('StorageClass', { fg = c.blue })
h('Structure', { fg = c.teal })
h('Typedef', { fg = c.teal })

-- ─── Constants ───────────────────────────────────────────────────────────
-- constant.language (true/false/null) → #569cd6
-- variable.other.constant / enummember → #4FC1FF
h('Constant', { fg = c.bright_blue })
h('Boolean', { fg = c.blue })

-- ─── Numbers ─────────────────────────────────────────────────────────────
-- constant.numeric → #b5cea8
h('Number', { fg = c.light_green })
h('Float', { fg = c.light_green })

-- ─── Strings ─────────────────────────────────────────────────────────────
-- string → #ce9178
h('String', { fg = c.orange })
h('Character', { fg = c.orange })

-- ─── Preprocessor ────────────────────────────────────────────────────────
h('PreProc', { fg = c.blue })
h('Include', { fg = c.pink })
h('Define', { fg = c.blue })
h('Macro', { fg = c.blue })
h('PreCondit', { fg = c.blue })

-- ─── Special ─────────────────────────────────────────────────────────────
-- constant.character.escape → #d7ba7d
h('Special', { fg = c.gold })
h('SpecialChar', { fg = c.gold })
h('Tag', { fg = c.blue })
h('SpecialComment', { fg = c.green })

-- ─── Identifiers ─────────────────────────────────────────────────────────
-- 局部变量在 semantic HL 下渲染为白色 (editor.foreground)
h('Identifier', { fg = c.fg })
h('Variable', { fg = c.fg })

-- ─── Operators & Delimiters ──────────────────────────────────────────────
-- keyword.operator → #d4d4d4
h('Operator', { fg = c.fg })
h('Delimiter', { fg = c.fg })

h('NonText', { fg = c.border })
h('WhiteSpace', { fg = blend(c.fg_dim, 0.70) })

-- ─── Comments ────────────────────────────────────────────────────────────
-- comment → #6A9955
h('Comment', { fg = c.green, italic = true })

-- =============================================================================
-- 4. UI Components
-- =============================================================================
h('StatusLine', { fg = c.fg_dim, bg = c.bg_sidebar })
h('StatusLineNC', { fg = c.fg_disabled, bg = c.bg_sidebar })
h('WildMenu', { fg = c.bg, bg = c.accent })
h('WinBar', { fg = c.fg_ui, bg = c.bg })
h('WinBarNC', { fg = c.fg_dim, bg = c.bg })
h('TabLine', { fg = c.fg_dim, bg = c.bg_sidebar })
h('TabLineFill', { bg = c.bg_sidebar })
h('TabLineSel', { fg = c.fg_ui, bg = c.bg, bold = true })

-- ─── Popup Menu ──────────────────────────────────────────────────────────
h('Pmenu', { fg = c.fg_ui, bg = c.bg_float })
h('PmenuSel', { bg = c.bg_selection }) -- ≈ #243239
h('PmenuSbar', { bg = c.bg_float })
h('PmenuThumb', { bg = c.fg_dim })
h('PmenuBorder', { fg = c.border })
h('PmenuMatch', { fg = c.blue, bold = true })

-- ─── Float & Borders ────────────────────────────────────────────────────
h('NormalFloat', { fg = c.fg_ui, bg = c.bg_float })
h('FloatBorder', { fg = c.border })
h('FloatTitle', { fg = c.fg_ui, bg = c.bg_float, bold = true })
h('Title', { fg = c.yellow, bold = true })

-- =============================================================================
-- 5. Messages & Misc
-- =============================================================================
h('ErrorMsg', { fg = c.diag_error, bold = true })
h('WarningMsg', { fg = c.diag_warn })
h('ModeMsg', { fg = c.accent, bold = true })
h('MoreMsg', { fg = c.accent })
h('Question', { fg = c.accent })
h('SpecialKey', { fg = c.fg_dim })
h('Todo', { fg = c.pink, bold = true, reverse = true })
h('MatchParen', { bg = blend(c.accent, 0.60), bold = true })
h('Underlined', { fg = c.accent, underline = true })
h('Directory', { fg = c.bright_blue })

h('qfFileName', { fg = c.bright_blue })
h('qfLineNr', { fg = c.accent })
h('qfSeparator', { fg = c.border })
h('QuickFixLine', { bg = c.bg_cursorline, bold = true })
h('qfText', { link = 'Normal' })

h('DiffAdd', { bg = blend(c.diff_add_bg, 0.74) })
h('DiffChange', { bg = blend(c.diag_warn, 0.80) })
h('DiffDelete', { bg = blend(c.diff_del_bg, 0.74) })
h('DiffText', { bg = blend(c.diag_warn, 0.60) })

h('SpellBad', { undercurl = true, sp = c.diag_error })
h('SpellCap', { undercurl = true, sp = c.diag_warn })
h('SpellLocal', { undercurl = true, sp = c.diag_info })
h('SpellRare', { undercurl = true, sp = c.pink })

-- =============================================================================
-- 6. Treesitter Highlights
-- =============================================================================

-- ─── Variables ───────────────────────────────────────────────────────────
-- 局部变量 → 白色 (#BBBEBF)，截图确认 rgb(230,230,230) 渲染
-- 参数 → 浅蓝 (#9CDCFE)
h('@variable', { fg = c.fg })
h('@variable.builtin', { link = '@variable' }) -- this/self → #569cd6
h('@variable.parameter', { link = '@variable' }) -- 参数 → #9CDCFE
h('@variable.parameter.builtin', { link = '@variable' })
h('@variable.member', { link = '@variable' }) -- 成员 → #9CDCFE
h('@parameter', { link = '@variable' })
h('@property', { link = '@variable' })

-- ─── Constants ───────────────────────────────────────────────────────────
h('@constant', { fg = c.fg }) -- #4FC1FF
h('@constant.builtin', { fg = c.fg }) -- constant.language → #569cd6
h('@constant.macro', { fg = c.fg })

-- ─── Modules ─────────────────────────────────────────────────────────────
h('@module', { fg = c.teal }) -- namespace → #4EC9B0
h('@module.builtin', { fg = c.teal })

h('@label', { fg = c.label_gray })

-- ─── Strings ─────────────────────────────────────────────────────────────
h('@string', { fg = c.orange }) -- #ce9178
h('@string.documentation', { fg = c.green, italic = true })
h('@string.regexp', { fg = c.red }) -- #d16969
h('@string.escape', { fg = c.gold }) -- #d7ba7d
h('@string.special', { fg = c.orange })
h('@string.special.symbol', { fg = c.orange })
h('@string.special.path', { fg = c.orange })
h('@string.special.url', { fg = c.accent, underline = true })

h('@character', { fg = c.orange })
h('@character.special', { fg = c.gold })

h('@boolean', { fg = c.blue }) -- constant.language → #569cd6
h('@number', { fg = c.light_green }) -- #b5cea8
h('@number.float', { fg = c.light_green })

-- ─── Types ───────────────────────────────────────────────────────────────
h('@type', { fg = c.teal }) -- #4EC9B0
h('@type.builtin', { fg = c.blue }) -- int/void → #569cd6
h('@type.definition', { fg = c.teal })

h('@attribute', { fg = c.teal })
h('@attribute.builtin', { fg = c.teal })

-- ─── Functions ───────────────────────────────────────────────────────────
h('@function', { fg = c.yellow }) -- #DCDCAA
h('@function.builtin', { fg = c.yellow })
h('@function.call', { fg = c.yellow })
h('@function.macro', { fg = c.yellow })
h('@function.method', { fg = c.yellow })
h('@function.method.call', { fg = c.yellow })
h('@constructor', { fg = c.teal })

h('@operator', { fg = c.fg })

-- ─── Keywords ────────────────────────────────────────────────────────────
h('@keyword', { fg = c.pink }) -- #C586C0
h('@keyword.coroutine', { fg = c.pink })
h('@keyword.function', { fg = c.blue }) -- storage → #569cd6
h('@keyword.operator', { fg = c.fg }) -- keyword.operator → fg
h('@keyword.import', { fg = c.pink }) -- using → #C586C0
h('@keyword.type', { fg = c.blue }) -- storage.type → #569cd6
h('@keyword.modifier', { fg = c.blue }) -- storage.modifier → #569cd6
h('@keyword.repeat', { fg = c.pink })
h('@keyword.return', { fg = c.pink })
h('@keyword.debug', { fg = c.pink })
h('@keyword.exception', { fg = c.pink })
h('@keyword.conditional', { fg = c.pink })
h('@keyword.conditional.ternary', { fg = c.fg })
h('@keyword.directive', { fg = c.pink })
h('@keyword.directive.define', { fg = c.blue })

-- ─── Punctuation ─────────────────────────────────────────────────────────
h('@punctuation', { fg = c.fg })
h('@punctuation.delimiter', { fg = c.fg })
h('@punctuation.bracket', { fg = c.fg })
h('@punctuation.special', { fg = c.blue }) -- template-expression → #569cd6

-- ─── Comments ────────────────────────────────────────────────────────────
h('@comment', { fg = c.green, italic = true })
h('@comment.documentation', { fg = c.green, italic = true })
h('@comment.error', { fg = c.diag_error, bold = true })
h('@comment.warning', { fg = c.diag_warn, bold = true })
h('@comment.todo', { fg = c.pink, bold = true })
h('@comment.note', { fg = c.accent, bold = true })

-- ─── Markup ──────────────────────────────────────────────────────────────
h('@markup', { fg = c.fg })
h('@markup.strong', { fg = c.blue, bold = true })
h('@markup.italic', { fg = c.pink, italic = true })
h('@markup.strikethrough', { strikethrough = true })
h('@markup.underline', { underline = true })
h('@markup.heading', { fg = c.blue, bold = true })
h('@markup.heading.1', { fg = c.blue, bold = true })
h('@markup.heading.2', { fg = c.blue, bold = true })
h('@markup.heading.3', { fg = c.blue, bold = true })
h('@markup.heading.4', { fg = c.blue, bold = true })
h('@markup.heading.5', { fg = c.blue, bold = true })
h('@markup.heading.6', { fg = c.blue, bold = true })
h('@markup.quote', { fg = c.green })
h('@markup.math', { fg = c.orange })
h('@markup.link', { fg = c.accent, underline = true })
h('@markup.link.label', { fg = c.accent })
h('@markup.link.url', { fg = c.accent, underline = true })
h('@markup.raw', { fg = c.orange })
h('@markup.raw.block', { fg = c.orange })
h('@markup.list', { fg = c.fg })
h('@markup.list.checked', { fg = c.teal })
h('@markup.list.unchecked', { fg = c.fg })

-- ─── Diff ────────────────────────────────────────────────────────────────
h('@diff.plus', { fg = c.git_add })
h('@diff.minus', { fg = c.git_delete })
h('@diff.delta', { fg = c.git_change })

-- ─── Tags (HTML/XML) ────────────────────────────────────────────────────
h('@tag', { fg = c.blue })
h('@tag.attribute', { fg = c.light_blue })
h('@tag.delimiter', { fg = c.gray })
h('@tag.builtin', { fg = c.blue })

h('@constant.comment', { link = 'SpecialComment' })
h('@number.comment', { link = 'Comment' })
h('@punctuation.bracket.comment', { link = 'SpecialComment' })
h('@punctuation.delimiter.comment', { link = 'SpecialComment' })
h('@label.vimdoc', { fg = c.orange })
h('@markup.heading.1.delimiter.vimdoc', { link = '@markup.heading.1' })
h('@markup.heading.2.delimiter.vimdoc', { link = '@markup.heading.2' })

h('@class', { fg = c.teal })
h('@method', { fg = c.yellow })
h('@interface', { fg = c.teal })
h('@namespace', { fg = c.teal })

-- =============================================================================
-- 7. LSP Semantic Highlights
-- =============================================================================
h('@lsp.type.class', { fg = c.teal })
h('@lsp.type.comment', { link = '@comment' })
h('@lsp.type.decorator', { fg = c.yellow })
h('@lsp.type.enum', { fg = c.teal })
h('@lsp.type.enumMember', { fg = c.bright_blue })
h('@lsp.type.event', { fg = c.teal })
h('@lsp.type.function', { fg = c.yellow })
h('@lsp.type.interface', { fg = c.teal })
h('@lsp.type.keyword', { fg = c.pink })
h('@lsp.type.macro', { fg = c.blue })
h('@lsp.type.method', { fg = c.yellow })
h('@lsp.type.modifier', { fg = c.blue })
h('@lsp.type.namespace', { fg = c.teal })
h('@lsp.type.number', { fg = c.light_green })
h('@lsp.type.operator', { fg = c.fg })
h('@lsp.type.parameter', { fg = c.light_blue })
h('@lsp.type.property', { fg = c.light_blue })
h('@lsp.type.regexp', { fg = c.red })
h('@lsp.type.string', { fg = c.orange })
h('@lsp.type.struct', { fg = c.teal })
h('@lsp.type.type', { fg = c.teal })
h('@lsp.type.typeParameter', { fg = c.teal })
h('@lsp.type.variable', { fg = c.fg }) -- 局部变量 → 白色

h('@lsp.mod.abstract', {})
h('@lsp.mod.async', {})
h('@lsp.mod.declaration', {})
h('@lsp.mod.defaultLibrary', {})
h('@lsp.mod.definition', {})
h('@lsp.mod.deprecated', { strikethrough = true })
h('@lsp.mod.documentation', {})
h('@lsp.mod.modification', {})
h('@lsp.mod.readonly', {})
h('@lsp.mod.static', {})

-- =============================================================================
-- 8. Diagnostics
-- =============================================================================
h('DiagnosticError', { fg = c.diag_error })
h('DiagnosticWarn', { fg = c.diag_warn })
h('DiagnosticInfo', { fg = c.diag_info })
h('DiagnosticHint', { fg = c.diag_hint })
h('DiagnosticOk', { fg = c.teal })

h('DiagnosticVirtualTextError', { fg = c.diag_error, bg = blend(c.diag_error, 0.88) })
h('DiagnosticVirtualTextWarn', { fg = c.diag_warn, bg = blend(c.diag_warn, 0.88) })
h('DiagnosticVirtualTextInfo', { fg = c.diag_info, bg = blend(c.diag_info, 0.88) })
h('DiagnosticVirtualTextHint', { fg = c.diag_hint, bg = blend(c.diag_hint, 0.88) })

h('DiagnosticUnderlineError', { undercurl = true, sp = c.diag_error })
h('DiagnosticUnderlineWarn', { undercurl = true, sp = c.diag_warn })
h('DiagnosticUnderlineInfo', { undercurl = true, sp = c.diag_info })
h('DiagnosticUnderlineHint', { undercurl = true, sp = c.diag_hint })

h('DiagnosticDeprecated', { strikethrough = true, sp = c.diag_warn })

-- Statusline diagnostic (muted)
h('DiagnosticERROR', { fg = blend(c.diag_error, 0.30) })
h('DiagnosticWARN', { fg = blend(c.diag_warn, 0.30) })
h('DiagnosticINFO', { fg = blend(c.diag_info, 0.30) })
h('DiagnosticHINT', { fg = blend(c.diag_hint, 0.30) })

h('YankHighlight', { fg = c.bg, bg = c.fg })

-- =============================================================================
-- 9. LSP & Plugin Support
-- =============================================================================
h('LspReferenceText', { bg = blend(c.bg_selection, 0.50) })
h('LspReferenceRead', { bg = blend(c.bg_selection, 0.50) })
h('LspReferenceWrite', { bg = blend(c.bg_selection, 0.40) })
h('LspReferenceTarget', { link = 'LspReferenceText' })
h('LspInlayHint', { fg = c.fg_dim, italic = true })
h('LspCodeLens', { fg = c.fg_dim })
h('LspCodeLensSeparator', { fg = c.fg_dim })
h('LspSignatureActiveParameter', { link = 'LspReferenceText' })

-- ─── Indentmini ──────────────────────────────────────────────────────────
h('IndentLine', { fg = blend(c.fg_dim, 0.70) })
h('IndentLineCurrent', { fg = c.fg_dim })

-- ─── GitSigns ────────────────────────────────────────────────────────────
h('GitSignsAdd', { fg = c.git_add })
h('GitSignsChange', { fg = c.git_change })
h('GitSignsDelete', { fg = c.git_delete })

-- ─── Dashboard ───────────────────────────────────────────────────────────
h('DashboardHeader', { fg = c.accent })

-- ─── Modeline ────────────────────────────────────────────────────────────
h('ModeLineFileName', { bold = true })
