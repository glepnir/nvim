-- orange    #cb4b16
-- violet    #6c71c4
local colors = {
  base04 = '#00202b',
  base03 = '#002838',
  -- base03 = '#002937',
  base02 = '#073642',
  base01 = '#586e75',
  base00 = '#657b83',
  base0 = '#839496',
  base1 = '#93a1a1',
  base2 = '#eee8d5',
  base3 = '#fdf6e3',
  yellow = '#b58900',
  orange = '#b86114',
  red = '#d75f5f',
  violet = '#887ec8',
  blue = '#268bd2',
  cyan = '#2aa198',
  green = '#84a800',
  magenta = '#d33682',
  -- Custom modifications
  fg = '#b2b2b2', -- Brighter foreground
}

vim.g.colors_name = 'solarized'

local function h(group, properties)
  vim.api.nvim_set_hl(0, group, properties)
end

local function hex_to_rgb(hex)
  hex = hex:gsub('#', '')
  return {
    tonumber(hex:sub(1, 2), 16),
    tonumber(hex:sub(3, 4), 16),
    tonumber(hex:sub(5, 6), 16),
  }
end

local function rgb_to_hex(c)
  return string.format('#%02x%02x%02x', c[1], c[2], c[3])
end

local function blend(fg, bg, t)
  local a, b = hex_to_rgb(fg), hex_to_rgb(bg)
  local c = {
    math.floor(a[1] * (1 - t) + b[1] * t + 0.5),
    math.floor(a[2] * (1 - t) + b[2] * t + 0.5),
    math.floor(a[3] * (1 - t) + b[3] * t + 0.5),
  }
  return rgb_to_hex(c)
end

-- General editor highlights
h('Normal', { fg = colors.fg, bg = colors.base03 })
h('EndOfBuffer', { fg = colors.base03 })
h('CursorLine', { bg = colors.base02 })
h('CursorLineNr', { fg = colors.base1, bg = colors.base02 })
h('LineNr', { fg = colors.base01 })
h('Comment', { fg = colors.base01, italic = true })
h('String', { fg = colors.cyan })
h('Function', { fg = colors.blue })
h('Keyword', { fg = colors.green })
h('Constant', { fg = colors.violet })
h('Identifier', { fg = colors.fg })
h('Statement', { fg = colors.green })
h('Number', { link = 'Constant' })
h('Float', { link = 'Number' })
h('PreProc', { fg = colors.orange })
h('Type', { fg = colors.yellow })
h('Special', { fg = colors.orange })
h('Operator', { fg = colors.base0 })
h('Underlined', { fg = colors.violet, underline = true })
h('Todo', { fg = colors.magenta, bold = true })
h('Error', { fg = colors.red, bg = colors.base03, bold = true })
h('WarningMsg', { fg = colors.orange })
h('IncSearch', { fg = colors.base03, bg = colors.orange })
h('Search', { fg = colors.base03, bg = colors.yellow })
h('Visual', { fg = colors.base01, bg = colors.base03, reverse = true })
h('Pmenu', { fg = colors.base0, bg = colors.base04 })
h('PmenuMatch', { fg = colors.cyan, bg = colors.base04, bold = true })
h('PmenuMatchSel', { fg = colors.cyan, bg = colors.base00, bold = true })
h('PmenuSel', { fg = colors.base3, bg = colors.base00 })
h('PmenuSbar', { bg = colors.base1 })
h('PmenuThumb', { bg = colors.base01 })
h('MatchParen', { bg = colors.base02 })
h('WinBar', { bg = colors.base02 })
h('NormalFloat', { bg = colors.base04 })
h('FloatBorder', { fg = colors.blue })
h('Title', { fg = colors.yellow })
h('WinSeparator', { fg = colors.base00 })
h('StatusLine', { bg = colors.base1, fg = colors.base02 })
h('StatusLineNC', { bg = colors.base00, fg = colors.base02 })
h('ModeMsg', { fg = colors.cyan })
h('ColorColumn', { bg = colors.base02 })
h('Title', { fg = colors.orange })
h('WildMenu', { fg = colors.base2, bg = colors.base02, reverse = true })
h('Folded', { bg = colors.base04, fg = colors.base0 })
h('ErrorMsg', { fg = colors.red })
h('ComplMatchIns', { fg = colors.base01 })
h('Directory', { fg = colors.cyan })
h('QuickFixLine', { bold = true })
h('qfFileName', { fg = colors.blue })
h('qfSeparator', { fg = colors.base01 })
h('qfLineNr', { link = 'LineNr' })
h('qfText', { link = 'Normal' })

-- Treesitter highlights
h('@variable', { link = 'Identifier' })
h('@variable.builtin', { link = '@variable' })
h('@variable.parameter', { link = '@variable' })
h('@variable.parameter.builtin', { link = '@variable.builtin' })
h('@variable.member', { link = '@variable' })

h('@constant', { link = 'Constant' })
h('@constant.builtin', { link = 'Constant' })
h('@constant.macro', { link = 'Constant' })

h('@module', { link = 'Identifier' })
h('@module.builtin', { link = '@module' })

h('@label', { link = 'Label' })
h('@string', { link = 'String' })
h('@string.documentation', { link = 'Comment' })
h('@string.regexp', { link = '@string' })
h('@string.escape', { link = 'SpecialChar' })
h('@string.special', { link = '@string' })
h('@string.special.symbol', { link = '@string' })
h('@string.special.path', { link = '@string' })
h('@string.special.url', { link = 'Underlined' })

h('@character', { link = 'String' })
h('@character.special', { link = '@character' })

h('@boolean', { link = 'Constant' })
h('@number', { link = 'Number' })
h('@number.float', { link = 'Float' })

h('@type', { link = 'Type' })
h('@type.builtin', { link = 'Special' })
h('@type.definition', { link = 'Type' })

h('@attribute', { link = 'Macro' })
h('@attribute.builtin', { link = 'Special' })
h('@property', { link = 'Identifier' })

h('@function', { link = 'Function' })
h('@function.builtin', { link = 'Function' })
h('@function.call', { link = '@function' })
h('@function.macro', { link = '@function' })
h('@function.method', { link = '@function' })
h('@function.method.call', { link = '@function' })
h('@constructor', { link = 'Function' })
h('@operator', { link = 'Operator' })

h('@keyword', { link = 'Keyword' })
h('@keyword.coroutine', { link = '@keyword' })
h('@keyword.function', { link = '@keyword' })
h('@keyword.operator', { link = '@keyword' })
h('@keyword.import', { link = '@keyword' })
h('@keyword.type', { link = '@keyword' })
h('@keyword.modifier', { link = '@keyword' })
h('@keyword.repeat', { link = '@keyword' })
h('@keyword.return', { link = '@keyword' })
h('@keyword.debug', { link = '@keyword' })
h('@keyword.exception', { link = '@keyword' })
h('@keyword.conditional', { link = '@keyword' })
h('@keyword.conditional.ternary', { link = '@operator' })
h('@keyword.directive', { link = '@keyword' })
h('@keyword.directive.define', { link = '@keyword' })

h('@punctuation', { fg = colors.fg })
h('@punctuation.delimiter', { link = '@punctuation' })
h('@punctuation.bracket', { link = '@punctuation' })
h('@punctuation.special', { link = '@punctuation' })

h('@comment', { link = 'Comment' })
h('@comment.documentation', { link = '@comment' })
h('@comment.error', { fg = colors.red, bold = true })
h('@comment.warning', { fg = colors.yellow, bold = true })
h('@comment.todo', { link = 'Special' })
h('@comment.note', { link = 'Special' })

h('@markup', { link = 'Comment' })
h('@markup.strong', { bold = true })
h('@markup.italic', { italic = true })
h('@markup.strikethrough', { strikethrough = true })
h('@markup.underline', { link = 'Underlined' })
h('@markup.heading', { link = 'Title' })
h('@markup.heading.1', { link = '@markup.heading' })
h('@markup.heading.2', { link = '@markup.heading' })
h('@markup.heading.3', { link = '@markup.heading' })
h('@markup.heading.4', { link = '@markup.heading' })
h('@markup.heading.5', { link = '@markup.heading' })
h('@markup.heading.6', { link = '@markup.heading' })
h('@markup.quote', {})
h('@markup.math', { link = 'String' })
h('@markup.link', { link = 'Underlined' })
h('@markup.link.label', { link = '@markup.link' })
h('@markup.link.url', { link = '@markup.link' })
h('@markup.raw', {})
h('@markup.raw.block', { link = '@markup.raw' })
h('@markup.list', {})
h('@markup.list.checked', { fg = colors.green })
h('@markup.list.unchecked', { link = '@markup.list' })

h('@diff.plus', { link = 'Added' })
h('@diff.minus', { link = 'Removed' })
h('@diff.delta', { link = 'Changed' })

h('@tag', { fg = colors.green })
h('@tag.attribute', { fg = colors.base0 })
h('@tag.delimiter', { fg = colors.base0 })
h('@tag.builtin', { link = 'Special' })

h('@constant.comment', { link = 'SpecialComment' })
h('@number.comment', { link = 'Comment' })
h('@punctuation.bracket.comment', { link = 'SpecialComment' })
h('@punctuation.delimiter.comment', { link = 'SpecialComment' })
h('@label.vimdoc', { link = 'String' })
h('@markup.heading.1.delimiter.vimdoc', { link = '@markup.heading.1' })
h('@markup.heading.2.delimiter.vimdoc', { link = '@markup.heading.2' })

h('@parameter', { fg = colors.base0 })
h('@class', { fg = colors.yellow })
h('@method', { fg = colors.blue })

h('@constant.comment', { link = 'SpecialComment' })
h('@number.comment', { link = 'Comment' })
h('@punctuation.bracket.comment', { link = 'SpecialComment' })
h('@punctuation.delimiter.comment', { link = 'SpecialComment' })
h('@label.vimdoc', { link = 'String' })
h('@markup.heading.1.delimiter.vimdoc', { link = '@markup.heading.1' })
h('@markup.heading.2.delimiter.vimdoc', { link = '@markup.heading.2' })

h('@interface', { fg = colors.yellow })
h('@namespace', { fg = colors.base0 })

-- Neovim LSP semantic highlights
h('@lsp.type.class', { link = '@type' })
h('@lsp.type.comment', { link = '@comment' })
h('@lsp.type.decorator', { link = '@attribute' })
h('@lsp.type.enum', { link = '@type' })
h('@lsp.type.enumMember', { link = '@constant' })
h('@lsp.type.event', { link = '@type' })
h('@lsp.type.function', { link = '@function' })
h('@lsp.type.interface', { link = '@type' })
h('@lsp.type.keyword', { link = '@keyword' })
h('@lsp.type.macro', { link = 'Macro' })
h('@lsp.type.method', { link = '@function.method' })
h('@lsp.type.modifier', { link = '@type.qualifier' })
h('@lsp.type.namespace', { link = '@module' })
h('@lsp.type.number', { link = '@number' })
h('@lsp.type.operator', { link = '@operator' })
h('@lsp.type.parameter', { link = '@variable.parameter' })
h('@lsp.type.property', { link = '@property' })
h('@lsp.type.regexp', { link = '@string.regexp' })
h('@lsp.type.string', { link = '@string' })
h('@lsp.type.struct', { link = '@type' })
h('@lsp.type.type', { link = '@type' })
h('@lsp.type.typeParameter', { link = '@type.definition' })
h('@lsp.type.variable', { link = '@variable' })

h('@lsp.mod.abstract', {})
h('@lsp.mod.async', {})
h('@lsp.mod.declaration', {})
h('@lsp.mod.defaultLibrary', {})
h('@lsp.mod.definition', {})
h('@lsp.mod.deprecated', { link = 'DiagnosticDeprecated' })
h('@lsp.mod.documentation', {})
h('@lsp.mod.modification', {})
h('@lsp.mod.readonly', {})
h('@lsp.mod.static', {})

-- Diagnostics
h('DiagnosticError', { fg = colors.red })
h('DiagnosticWarn', { fg = colors.yellow })
h('DiagnosticInfo', { fg = colors.blue })
h('DiagnosticHint', { fg = colors.cyan })
h('DiagnosticVirtualTextError', { bg = blend(colors.red, colors.base03, 0.5) })
h('DiagnosticVirtualTextWarn', { bg = blend(colors.yellow, colors.base03, 0.5) })
h('DiagnosticVirtualTextInfo', { bg = blend(colors.blue, colors.base03, 0.5) })
h('DiagnosticUnderlineError', { undercurl = true, sp = colors.red })
h('DiagnosticUnderlineWarn', { undercurl = true, sp = colors.yellow })
h('DiagnosticUnderlineInfo', { undercurl = true, sp = colors.blue })
h('DiagnosticUnderlineHint', { undercurl = true, sp = colors.cyan })

-- LSP
h('LspReferenceText', { bg = colors.base02 })
h('LspReferenceRead', { bg = colors.base02 })
h('LspReferenceWrite', { bg = colors.base02 })
h('LspReferenceTarget', { link = 'LspReferenceText' })
h('LspInlayHint', { link = 'NonText' })
h('LspCodeLens', { link = 'NonText' })
h('LspCodeLensSeparator', { link = 'NonText' })
h('LspSignatureActiveParameter', { link = 'LspReferenceText' })

-- Indentmini
h('IndentLine', { link = 'Comment' })
h('IndentLineCurrent', { fg = '#084352' })

-- GitSigns
h('GitSignsAdd', { fg = colors.green, bg = colors.base03 })
h('GitSignsChange', { fg = colors.yellow, bg = colors.base03 })
h('GitSignsDelete', { fg = colors.red, bg = colors.base03 })
h('DashboardHeader', { fg = colors.green })
h('ModeLineMode', { bold = true })
h('ModeLinefileinfo', { bold = true })
