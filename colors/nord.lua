-- Nord colorscheme for Neovim
-- Based on https://www.nordtheme.com/docs/colors-and-palettes
-- Maintainer: glepnir

local M = {}

M.palette = {
  -- Polar Night
  nord0 = '#2E3440',
  nord1 = '#3B4252',
  nord2 = '#434C5E',
  nord3 = '#4C566A',
  -- Snow Storm
  nord4 = '#D8DEE9',
  nord5 = '#E5E9F0',
  nord6 = '#ECEFF4',
  -- Frost
  nord7 = '#8FBCBB',
  nord8 = '#88C0D0',
  nord9 = '#81A1C1',
  nord10 = '#5E81AC',
  -- Aurora
  nord11 = '#BF616A',
  nord12 = '#D08770',
  nord13 = '#EBCB8B',
  nord14 = '#A3BE8C',
  nord15 = '#B48EAD',
}

local p = M.palette
vim.cmd('highlight clear')
if vim.fn.exists('syntax_on') then
  vim.cmd('syntax reset')
end
vim.o.background = 'dark'
vim.g.colors_name = 'nord'

local hi = function(name, opts)
  vim.api.nvim_set_hl(0, name, opts)
end

-- ─── Editor UI ───────────────────────────────────────────────────────
hi('Normal', { fg = p.nord4, bg = p.nord0 })
hi('NormalFloat', { fg = p.nord4, bg = p.nord1 })
hi('FloatBorder', { fg = p.nord8, bg = p.nord1 })
hi('FloatTitle', { fg = p.nord8, bg = p.nord1, bold = true })
hi('NormalNC', { fg = p.nord4, bg = p.nord0 })
hi('ColorColumn', { bg = p.nord1 })
hi('Conceal', { fg = p.nord3 })
hi('Cursor', { fg = p.nord0, bg = p.nord4 })
hi('CursorColumn', { bg = p.nord1 })
hi('CursorLine', { bg = p.nord1 })
hi('CursorLineNr', { fg = p.nord4, bg = p.nord1, bold = true })
hi('DiffAdd', { fg = p.nord14, bg = p.nord1 })
hi('DiffChange', { fg = p.nord13, bg = p.nord1 })
hi('DiffDelete', { fg = p.nord11, bg = p.nord1 })
hi('DiffText', { fg = p.nord13, bg = p.nord2, bold = true })
hi('Directory', { fg = p.nord8 })
hi('EndOfBuffer', { fg = p.nord1 })
hi('ErrorMsg', { fg = p.nord11, bold = true })
hi('FoldColumn', { fg = p.nord3, bg = p.nord0 })
hi('Folded', { fg = p.nord3, bg = p.nord1 })
hi('IncSearch', { fg = p.nord0, bg = p.nord13, bold = true })
hi('CurSearch', { fg = p.nord0, bg = p.nord13, bold = true })
hi('LineNr', { fg = p.nord3 })
hi('MatchParen', { fg = p.nord8, bg = p.nord3, bold = true })
hi('ModeMsg', { fg = p.nord4, bold = true })
hi('MoreMsg', { fg = p.nord14 })
hi('MsgArea', { fg = p.nord4 })
hi('NonText', { fg = p.nord2 })
hi('Pmenu', { fg = p.nord4, bg = p.nord2 })
hi('PmenuSel', { fg = p.nord0, bg = p.nord8, bold = true })
hi('PmenuSbar', { bg = p.nord2 })
hi('PmenuThumb', { bg = p.nord3 })
hi('Question', { fg = p.nord14 })
hi('QuickFixLine', { fg = p.nord8, bold = true })
hi('Search', { fg = p.nord0, bg = p.nord8 })
hi('SignColumn', { fg = p.nord3, bg = p.nord0 })
hi('SpecialKey', { fg = p.nord3 })
hi('SpellBad', { sp = p.nord11, undercurl = true })
hi('SpellCap', { sp = p.nord13, undercurl = true })
hi('SpellLocal', { sp = p.nord14, undercurl = true })
hi('SpellRare', { sp = p.nord15, undercurl = true })
hi('StatusLine', { fg = p.nord4, bg = p.nord2 })
hi('StatusLineNC', { fg = p.nord3, bg = p.nord1 })
hi('Substitute', { fg = p.nord0, bg = p.nord12 })
hi('TabLine', { fg = p.nord3, bg = p.nord1 })
hi('TabLineFill', { bg = p.nord0 })
hi('TabLineSel', { fg = p.nord8, bg = p.nord2, bold = true })
hi('Title', { fg = p.nord8, bold = true })
hi('VertSplit', { fg = p.nord2, bg = p.nord0 })
hi('WinSeparator', { fg = p.nord2, bg = p.nord0 })
hi('Visual', { bg = p.nord2 })
hi('VisualNOS', { bg = p.nord2 })
hi('WarningMsg', { fg = p.nord13, bold = true })
hi('Whitespace', { fg = p.nord2 })
hi('WildMenu', { fg = p.nord0, bg = p.nord8 })
hi('WinBar', { fg = p.nord4, bg = p.nord1 })
hi('WinBarNC', { fg = p.nord3, bg = p.nord1 })

-- ─── Syntax ──────────────────────────────────────────────────────────
hi('Comment', { fg = p.nord3, italic = true })
hi('Constant', { fg = p.nord4 })
hi('String', { fg = p.nord14 })
hi('Character', { fg = p.nord14 })
hi('Number', { fg = p.nord15 })
hi('Boolean', { fg = p.nord9 })
hi('Float', { fg = p.nord15 })
hi('Identifier', { fg = p.nord4 })
hi('Function', { fg = p.nord8 })
hi('Statement', { fg = p.nord9 })
hi('Conditional', { fg = p.nord9 })
hi('Repeat', { fg = p.nord9 })
hi('Label', { fg = p.nord9 })
hi('Operator', { fg = p.nord9 })
hi('Keyword', { fg = p.nord9 })
hi('Exception', { fg = p.nord11 })
hi('PreProc', { fg = p.nord9 })
hi('Include', { fg = p.nord9 })
hi('Define', { fg = p.nord9 })
hi('Macro', { fg = p.nord9 })
hi('PreCondit', { fg = p.nord9 })
hi('Type', { fg = p.nord7 })
hi('StorageClass', { fg = p.nord9 })
hi('Structure', { fg = p.nord7 })
hi('Typedef', { fg = p.nord7 })
hi('Special', { fg = p.nord12 })
hi('SpecialChar', { fg = p.nord12 })
hi('Tag', { fg = p.nord8 })
hi('Delimiter', { fg = p.nord4 })
hi('SpecialComment', { fg = p.nord8 })
hi('Debug', { fg = p.nord11 })
hi('Underlined', { underline = true })
hi('Ignore', { fg = p.nord3 })
hi('Error', { fg = p.nord11, bold = true })
hi('Todo', { fg = p.nord0, bg = p.nord13, bold = true })

-- ─── Treesitter ──────────────────────────────────────────────────────
hi('@comment', { link = 'Comment' })
hi('@comment.documentation', { fg = p.nord3, italic = true })
hi('@keyword', { link = 'Keyword' })
hi('@keyword.return', { fg = p.nord9 })
hi('@keyword.operator', { fg = p.nord9 })
hi('@keyword.import', { fg = p.nord9 })
hi('@keyword.coroutine', { fg = p.nord9 })
hi('@keyword.function', { fg = p.nord9 })
hi('@keyword.conditional', { fg = p.nord9 })
hi('@keyword.repeat', { fg = p.nord9 })
hi('@keyword.exception', { fg = p.nord11 })
hi('@function', { link = 'Function' })
hi('@function.builtin', { fg = p.nord8, italic = true })
hi('@function.macro', { fg = p.nord8 })
hi('@function.method', { fg = p.nord8 })
hi('@constructor', { fg = p.nord7 })
hi('@variable', { fg = p.nord4 })
hi('@variable.builtin', { fg = p.nord9, italic = true })
hi('@variable.parameter', { fg = p.nord4 })
hi('@variable.member', { fg = p.nord4 })
hi('@type', { link = 'Type' })
hi('@type.builtin', { fg = p.nord9 })
hi('@type.qualifier', { fg = p.nord9 })
hi('@string', { link = 'String' })
hi('@string.escape', { fg = p.nord12 })
hi('@string.regexp', { fg = p.nord12 })
hi('@string.special.url', { fg = p.nord8, underline = true })
hi('@number', { link = 'Number' })
hi('@number.float', { link = 'Float' })
hi('@boolean', { link = 'Boolean' })
hi('@constant', { fg = p.nord4 })
hi('@constant.builtin', { fg = p.nord9 })
hi('@constant.macro', { fg = p.nord9 })
hi('@attribute', { fg = p.nord12 })
hi('@operator', { link = 'Operator' })
hi('@punctuation.bracket', { fg = p.nord4 })
hi('@punctuation.delimiter', { fg = p.nord4 })
hi('@punctuation.special', { fg = p.nord9 })
hi('@namespace', { fg = p.nord4 })
hi('@module', { fg = p.nord4 })
hi('@label', { fg = p.nord9 })
hi('@tag', { fg = p.nord9 })
hi('@tag.attribute', { fg = p.nord7 })
hi('@tag.delimiter', { fg = p.nord4 })
hi('@markup.heading', { fg = p.nord8, bold = true })
hi('@markup.raw', { fg = p.nord7 })
hi('@markup.link', { fg = p.nord9 })
hi('@markup.link.label', { fg = p.nord8 })
hi('@markup.link.url', { fg = p.nord8, underline = true })
hi('@markup.italic', { italic = true })
hi('@markup.strong', { bold = true })
hi('@markup.strikethrough', { strikethrough = true })
hi('@markup.list', { fg = p.nord9 })
hi('@diff.plus', { fg = p.nord14 })
hi('@diff.minus', { fg = p.nord11 })
hi('@diff.delta', { fg = p.nord13 })

-- ─── LSP ─────────────────────────────────────────────────────────────
hi('LspReferenceText', { bg = p.nord2 })
hi('LspReferenceRead', { bg = p.nord2 })
hi('LspReferenceWrite', { bg = p.nord2, bold = true })
hi('LspSignatureActiveParameter', { fg = p.nord13, bold = true })
hi('LspInlayHint', { fg = p.nord3, bg = p.nord1, italic = true })
hi('LspCodeLens', { fg = p.nord3, italic = true })

-- Diagnostics
hi('DiagnosticError', { fg = p.nord11 })
hi('DiagnosticWarn', { fg = p.nord13 })
hi('DiagnosticInfo', { fg = p.nord8 })
hi('DiagnosticHint', { fg = p.nord7 })
hi('DiagnosticOk', { fg = p.nord14 })
hi('DiagnosticUnderlineError', { sp = p.nord11, undercurl = true })
hi('DiagnosticUnderlineWarn', { sp = p.nord13, undercurl = true })
hi('DiagnosticUnderlineInfo', { sp = p.nord8, undercurl = true })
hi('DiagnosticUnderlineHint', { sp = p.nord7, undercurl = true })
hi('DiagnosticVirtualTextError', { fg = p.nord11, bg = p.nord1, italic = true })
hi('DiagnosticVirtualTextWarn', { fg = p.nord13, bg = p.nord1, italic = true })
hi('DiagnosticVirtualTextInfo', { fg = p.nord8, bg = p.nord1, italic = true })
hi('DiagnosticVirtualTextHint', { fg = p.nord7, bg = p.nord1, italic = true })
hi('DiagnosticSignError', { fg = p.nord11 })
hi('DiagnosticSignWarn', { fg = p.nord13 })
hi('DiagnosticSignInfo', { fg = p.nord8 })
hi('DiagnosticSignHint', { fg = p.nord7 })

-- ─── Git ─────────────────────────────────────────────────────────────
hi('gitcommitHeader', { fg = p.nord9 })
hi('gitcommitSummary', { fg = p.nord4 })
hi('gitcommitBranch', { fg = p.nord8, bold = true })
hi('gitcommitSelectedType', { fg = p.nord14 })
hi('gitcommitDiscardedType', { fg = p.nord11 })
hi('gitcommitUntrackedFile', { fg = p.nord3 })
