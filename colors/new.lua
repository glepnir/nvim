--- Slim, low-distraction colour scheme inspired by zenwritten and evergarden.
--- https://github.com/zenbones-theme/zenbones.nvim
--- https://github.com/everviolet/nvim

local api = vim.api

vim.cmd.highlight('clear')
vim.o.background = 'dark'
vim.g.colors_name = 'zenjungle'

-- Helpers {{{1
local function hl(name, val)
  if type(val) == 'string' then
    val = { link = val }
  else
    assert(type(val) == 'table')
    if type(val.fg) == 'table' then
      local color = val.fg
      val.fg = color[1]
      val.ctermfg = color[2]
    end
    if type(val.bg) == 'table' then
      local color = val.bg
      val.bg = color[1]
      val.ctermbg = color[2]
    end
    if type(val.sp) == 'table' then
      val.sp = val.sp[1]
    end
  end
  return api.nvim_set_hl(0, name, val)
end

local function hl_term(colors)
  assert(#colors == 16)
  for i, color in ipairs(colors) do
    vim.g['terminal_color_' .. (i - 1)] = ('#%x'):format(color[1])
  end
end

local p_mt = { -- To catch bugs.
  __index = function(t, k)
    local v = rawget(t, k)
    if v == nil then
      error('Invalid key: ' .. k)
    end
    return v
  end,
}

-- Palette {{{1
local p = setmetatable({
  bg0_float = { 0x141816, 233 },
  bg0 = { 0x171c19, 234 },
  bg1 = { 0x1d2420, 235 },
  bg2 = { 0x232b27, 235 },
  bg3 = { 0x2e3833, 236 },

  fg0 = { 0xe3e6d3, 187 },
  fg0_alt1 = { 0xb7c0a0, 144 },
  fg0_alt2 = { 0xbdad76, 143 },
  fg0_alt3 = { 0x969b82, 144 },
  fg1 = { 0x76827a, 245 },
  fg2 = { 0x56605a, 241 },
  fg3 = { 0x3d4743, 239 },

  red = { 0xde6e7c, 168 },
  green = { 0x819b69, 107 },
  yellow = { 0xb79a64, 143 },
  blue = { 0x6099c0, 67 },
  magenta = { 0xb279a7, 139 },
  cyan = { 0x66a5ad, 73 },

  br_red = { 0xe8838f, 174 },
  br_green = { 0x8bae68, 107 },
  br_yellow = { 0xd6b667, 179 },
  br_blue = { 0x61abda, 74 },
  br_magenta = { 0xcf86c1, 175 },
  br_cyan = { 0x65b8c1, 73 },

  bg_diff_red = { 0x3c2424, 52 },
  bg_diff_green = { 0x323c24, 22 },
  bg_diff_blue = { 0x24333c, 17 },
  bg_diff_cyan = { 0x243c3a, 24 },

  pure_black = { 0x000000, 16 },
}, p_mt)

p.fg_comment = p.fg2
p.fg_delim = p.fg0_alt3
p.fg_kw = p.fg0_alt1
p.fg_number = p.fg0_alt2
p.fg_oper = p.fg0_alt1
p.fg_string = p.fg0_alt2
p.fg_type = p.fg0

-- Terminal buffers (:h terminal-config) {{{1
hl_term({
  p.bg2,
  p.red,
  p.green,
  p.yellow,
  p.blue,
  p.magenta,
  p.cyan,
  p.fg2,
  p.fg3,
  p.br_red,
  p.br_green,
  p.br_yellow,
  p.br_blue,
  p.br_magenta,
  p.br_cyan,
  p.fg0,
})

-- Editor groups (:h highlight-groups) {{{1
hl('ColorColumn', { bg = p.bg2 })
hl('Conceal', 'Comment')
hl('CurSearch', 'IncSearch')
hl('Cursor', { fg = 'bg', bg = 'fg' })
hl('lCursor', 'Cursor')
hl('CursorIM', 'Cursor')
hl('CursorColumn', 'CursorLine')
hl('CursorLine', { bg = p.bg1 })
hl('Directory', { fg = p.fg0_alt2 })
hl('DiffAdd', { bg = p.bg_diff_green })
hl('DiffChange', { bg = p.bg_diff_blue })
hl('DiffDelete', { bg = p.bg_diff_red })
hl('DiffText', { bg = p.bg_diff_cyan })
hl('DiffTextAdd', 'DiffText')
hl('EndOfBuffer', { fg = p.fg3 })
hl('TermCursor', 'Cursor')
hl('OkMsg', { fg = p.green })
hl('WarningMsg', { fg = p.br_yellow })
hl('ErrorMsg', { fg = p.red })
hl('StderrMsg', 'ErrorMsg')
hl('StdoutMsg', 'Normal')
hl('WinSeparator', { fg = p.bg3 })
hl('Folded', { fg = p.fg2, bg = p.bg2 })
hl('FoldColumn', { fg = p.fg3 })
hl('SignColumn', { fg = p.fg0 })
hl('IncSearch', { fg = p.bg0, bg = p.magenta })
hl('Substitute', 'Search')
hl('LineNr', { fg = p.fg3 })
hl('LineNrAbove', 'LineNr')
hl('LineNrBelow', 'LineNrAbove')
hl('CursorLineNr', { fg = p.fg0, bg = p.bg1 })
hl('CursorLineFold', 'FoldColumn')
hl('CursorLineSign', 'SignColumn')
hl('MatchParen', { fg = p.magenta, bold = true })
hl('ModeMsg', { fg = p.fg0, bold = true })
hl('MsgArea', 'Normal')
hl('MsgSeparator', 'StatusLine')
hl('MoreMsg', 'ModeMsg')
hl('NonText', { fg = p.fg3 })
hl('Normal', { fg = p.fg0, bg = p.bg0 })
hl('NormalFloat', { bg = p.bg0_float })
hl('FloatBorder', 'NormalFloat')
hl('FloatShadow', { bg = p.pure_black, blend = 80 })
hl('FloatShadowThrough', 'FloatShadow')
hl('FloatTitle', 'FloatBorder')
hl('FloatFooter', 'FloatTitle')
hl('NormalNC', 'Normal')
hl('Pmenu', { fg = p.fg0, bg = p.bg3 })
hl('PmenuSel', { fg = p.bg0, bg = p.fg1 })
hl('PmenuKind', { fg = p.fg1 })
hl('PmenuKindSel', 'PmenuSel')
hl('PmenuExtra', { fg = p.fg2 })
hl('PmenuExtraSel', 'PmenuSel')
hl('PmenuSbar', { bg = p.bg2 })
hl('PmenuThumb', { bg = p.fg0 })
hl('PmenuMatch', { bold = true })
hl('PmenuMatchSel', { bold = true })
hl('PmenuBordeblue', 'FloatBorder')
hl('PmenuShadow', 'FloatShadow')
hl('PmenuShadowThrough', 'PmenuShadow')
hl('ComplMatchIns', {})
hl('PreInsert', 'Added')
hl('ComplHint', { fg = p.fg2 })
hl('ComplHintMore', { fg = p.fg2, bold = true })
hl('Question', 'Title')
hl('QuickFixLine', { bg = p.bg2 })
hl('Search', { fg = p.bg0, bg = p.yellow })
hl('SnippetTabstop', 'Visual')
hl('SnippetTabstopActive', 'SnippetTabstop')
hl('SpecialKey', 'SpecialChar')
hl('SpellBad', { sp = p.red, undercurl = true })
hl('SpellCap', { sp = p.blue, undercurl = true })
hl('SpellLocal', { sp = p.cyan, undercurl = true })
hl('SpellRare', { sp = p.magenta, undercurl = true })
hl('StatusLine', { fg = p.fg0, bg = p.bg3 })
hl('StatusLineNC', { fg = p.fg2, bg = p.bg2 })
hl('StatusLineTerm', 'StatusLine')
hl('StatusLineTermNC', 'StatusLineNC')
hl('TabLine', 'StatusLineNC')
hl('TabLineFill', 'StatusLineNC')
hl('TabLineSel', 'StatusLine')
hl('Title', { fg = p.fg0, bold = true })
hl('Visual', { fg = p.bg0, bg = p.fg1 })
hl('VisualNOS', 'Visual')
hl('Whitespace', { fg = p.fg3 })
hl('WildMenu', 'Visual')
hl('WinBar', 'TabLineSel')
hl('WinBarNC', 'TabLine')
-- hl("Menu", "Pmenu") -- Unused
-- hl("Scrollbar", "PmenuSbar") -- Unused
-- hl("Tooltip", "Pmenu") -- Unused

-- Syntax groups (:h group-name) {{{1
hl('Comment', { fg = p.fg_comment })
hl('Constant', 'Identifier')
hl('String', { fg = p.fg_string })
hl('Character', 'String')
hl('Number', { fg = p.fg_number })
hl('Boolean', 'Constant')
hl('Float', 'Number')
hl('Identifier', { fg = p.fg0 })
hl('Function', 'Identifier')
hl('Statement', 'Keyword')
hl('Conditional', 'Keyword')
hl('Repeat', 'Keyword')
hl('Label', 'Keyword')
hl('Operator', { fg = p.fg_oper })
hl('Keyword', { fg = p.fg_kw })
hl('Exception', 'Keyword')
hl('PreProc', 'Keyword')
hl('Include', 'PreProc')
hl('Define', 'PreProc')
hl('Macro', 'PreProc')
hl('PreCondit', 'PreProc')
hl('Type', { fg = p.fg_type })
hl('StorageClass', 'Keyword')
hl('Structure', 'Keyword')
hl('Typedef', 'Type')
hl('Special', { fg = p.fg0 })
hl('SpecialChar', { fg = p.fg_string, bold = true })
hl('Tag', 'Special')
hl('Delimiter', { fg = p.fg_delim })
hl('SpecialComment', { fg = p.fg_comment, bold = true })
hl('Debug', 'Identifier')
hl('Underlined', { underline = true })
hl('Ignore', 'Comment')
hl('Error', { fg = p.red })
hl('Todo', 'SpecialComment')
hl('Added', { fg = p.green })
hl('Changed', { fg = p.blue })
hl('Removed', { fg = p.red })

-- Diagnostic groups (:h diagnostic-highlights) {{{1
hl('DiagnosticError', { fg = p.red })
hl('DiagnosticWarn', { fg = p.br_yellow })
hl('DiagnosticInfo', { fg = p.blue })
hl('DiagnosticHint', { fg = p.magenta })
hl('DiagnosticOk', { fg = p.green })
hl('DiagnosticVirtualTextError', 'DiagnosticError')
hl('DiagnosticVirtualTextWarn', 'DiagnosticWarn')
hl('DiagnosticVirtualTextInfo', 'DiagnosticInfo')
hl('DiagnosticVirtualTextHint', 'DiagnosticHint')
hl('DiagnosticVirtualTextOk', 'DiagnosticOk')
hl('DiagnosticVirtualLinesError', 'DiagnosticVirtualTextError')
hl('DiagnosticVirtualLinesWarn', 'DiagnosticVirtualTextWarn')
hl('DiagnosticVirtualLinesInfo', 'DiagnosticVirtualTextInfo')
hl('DiagnosticVirtualLinesHint', 'DiagnosticVirtualTextHint')
hl('DiagnosticVirtualLinesOk', 'DiagnosticVirtualTextOk')
hl('DiagnosticUnderlineError', { sp = p.red, undercurl = true })
hl('DiagnosticUnderlineWarn', { sp = p.br_yellow, undercurl = true })
hl('DiagnosticUnderlineInfo', { sp = p.blue, undercurl = true })
hl('DiagnosticUnderlineHint', { sp = p.magenta, undercurl = true })
hl('DiagnosticUnderlineOk', { sp = p.green, undercurl = true })
hl('DiagnosticFloatingError', 'DiagnosticError')
hl('DiagnosticFloatingWarn', 'DiagnosticWarn')
hl('DiagnosticFloatingInfo', 'DiagnosticInfo')
hl('DiagnosticFloatingHint', 'DiagnosticHint')
hl('DiagnosticFloatingOk', 'DiagnosticOk')
hl('DiagnosticSignError', 'DiagnosticError')
hl('DiagnosticSignWarn', 'DiagnosticWarn')
hl('DiagnosticSignInfo', 'DiagnosticInfo')
hl('DiagnosticSignHint', 'DiagnosticHint')
hl('DiagnosticSignOk', 'DiagnosticOk')
hl('DiagnosticDeprecated', { sp = p.fg0, strikethrough = true })
hl('DiagnosticUnnecessary', 'Comment')

-- Tree-sitter groups (:h treesitter-highlight-groups) {{{1
-- Although tree-sitter-style groups implement a fallback mechanism, we
-- explicitly define all standard groups instead.
hl('@variable', 'Identifier')
hl('@variable.builtin', '@variable')
hl('@variable.parameter', '@variable')
hl('@variable.parameter.builtin', '@variable.parameter')
hl('@variable.member', '@variable')

hl('@constant', 'Constant')
hl('@constant.builtin', '@constant')
hl('@constant.macro', '@constant')

hl('@module', 'Identifier')
hl('@module.builtin', '@module')
hl('@label', 'Identifier')

hl('@string', 'String')
hl('@string.documentation', '@string')
hl('@string.regexp', '@string')
hl('@string.escape', 'SpecialChar')
hl('@string.special', '@string')
hl('@string.special.symbol', '@string')
hl('@string.special.path', '@string')
hl('@string.special.url', 'Underlined')

hl('@character', 'Character')
hl('@character.special', '@operator')

hl('@boolean', 'Boolean')
hl('@number', 'Number')
hl('@number.float', 'Float')

hl('@type', 'Type')
hl('@type.builtin', '@type')
hl('@type.definition', '@type')

hl('@attribute', 'Identifier')
hl('@attribute.builtin', '@attribute')
hl('@property', 'Identifier')

hl('@function', 'Function')
hl('@function.builtin', '@function.call')
hl('@function.call', 'Function')
hl('@function.macro', '@function.call')

hl('@function.method', '@function')
hl('@function.method.call', '@function.call')

hl('@constructor', 'Identifier')
hl('@operator', 'Operator')

hl('@keyword', 'Keyword')
hl('@keyword.coroutine', '@keyword')
hl('@keyword.function', '@keyword')
hl('@keyword.operator', '@keyword')
hl('@keyword.import', '@keyword')
hl('@keyword.type', '@keyword')
hl('@keyword.modifier', 'StorageClass')
hl('@keyword.repeat', 'Repeat')
hl('@keyword.return', '@keyword')
hl('@keyword.debug', '@keyword')
hl('@keyword.exception', 'Exception')

hl('@keyword.conditional', 'Conditional')
hl('@keyword.conditional.ternary', '@operator')

hl('@keyword.directive', 'PreProc')
hl('@keyword.directive.define', '@keyword.directive')

hl('@punctuation', 'Delimiter') -- Non-standard; used as a link target.
hl('@punctuation.delimiter', '@punctuation')
hl('@punctuation.bracket', '@punctuation')
hl('@punctuation.special', '@punctuation')

hl('@comment', 'Comment')
hl('@comment.documentation', '@comment')

hl('@comment.error', { fg = p.red, bold = true })
hl('@comment.warning', { fg = p.br_yellow, bold = true })
hl('@comment.todo', 'SpecialComment')
hl('@comment.note', 'SpecialComment')

hl('@markup.strong', { bold = true })
hl('@markup.italic', { italic = true })
hl('@markup.strikethrough', { strikethrough = true })
hl('@markup.underline', 'Underlined')

hl('@markup.heading', 'Title')
hl('@markup.heading.1', '@markup.heading')
hl('@markup.heading.2', '@markup.heading')
hl('@markup.heading.3', '@markup.heading')
hl('@markup.heading.4', '@markup.heading')
hl('@markup.heading.5', '@markup.heading')
hl('@markup.heading.6', '@markup.heading')

hl('@markup.quote', 'Special')
hl('@markup.math', 'Special')

hl('@markup.link', 'Underlined')
hl('@markup.link.label', '@markup.link')
hl('@markup.link.url', '@markup.link')

hl('@markup.raw', 'Special')
hl('@markup.raw.block', '@markup.raw')

hl('@markup.list', 'Special')
hl('@markup.list.checked', '@markup.list')
hl('@markup.list.unchecked', '@markup.list')

hl('@diff.plus', 'Added')
hl('@diff.minus', 'Removed')
hl('@diff.delta', 'Changed')

hl('@tag', 'Tag')
hl('@tag.builtin', '@tag')
hl('@tag.attribute', '@tag')
hl('@tag.delimiter', '@tag')

-- Comment parser overrides
hl('@constant.comment', 'Comment')
hl('@constant.comment', 'Comment')
hl('@number.comment', 'Comment')
hl('@punctuation.bracket.comment', 'Comment')
hl('@punctuation.delimiter.comment', 'Comment')

-- p, p++ parser overrides
hl('@keyword.import.p', 'Include')
hl('@keyword.import.cpp', 'Include')

-- Lua parser overrides
hl('@constructor.lua', {})

-- LSP semantic groups (:h lsp-semantic-highlight) {{{1
-- Can refer to calls, but links @function by default, which is for definitions.
hl('@lsp.type.function', 'Function')
-- Typically it's more useful to guess a more specific group based on where the
-- macro is being used. May still be useful for combined highlights, though.
hl('@lsp.type.macro', {})
-- Ensures the signs of numbers still use @constant.
hl('@lsp.type.operator', {})

-- LSP other groups (:h lsp-highlight) {{{1
hl('LspReferenceText', { bg = p.bg2 })
hl('LspReferenceRead', 'LspReferenceText')
hl('LspReferenceWrite', 'LspReferenceText')
hl('LspReferenceTarget', 'LspReferenceText')
hl('LspInlayHint', 'NonText')
hl('LspCodeLens', { fg = p.fg2 })
hl('LspCodeLensSeparator', 'LspCodeLens')
hl('LspSignatureActiveParameter', 'LspReferenceText')

-- syntax/vim.vim overrides {{{1
hl('vimCommentTitle', 'SpecialComment')
hl('vimFunctionName', 'Function')
hl('vimUserFunc', 'Function')

-- syntax/lua.vim overrides {{{1
hl('luaFunction', 'Keyword')
hl('luaTable', 'Delimiter')

-- copilot.vim {{{1
hl('CopilotSuggestion', 'ComplHint')

-- fzf-lua {{{1
vim.g.fzf_colors = {
  ['hl'] = { 'bg', 'Search' },
  ['hl+'] = { 'bg', 'IncSearch' },
}

-- }}}1
-- vim: fdm=marker
