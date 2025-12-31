local function oklab_to_linear_rgb(L, a, b)
  -- Oklab to LMS conversion
  -- Reference: Björn Ottosson, "A perceptual color space for image processing"
  local l = L + 0.3963377774 * a + 0.2158037573 * b
  local m = L - 0.1055613458 * a - 0.0638541728 * b
  local s = L - 0.0894841775 * a - 1.2914855480 * b

  -- LMS to linear RGB
  -- Cube the LMS values (inverse of cube root)
  local l3, m3, s3 = l * l * l, m * m * m, s * s * s

  -- Linear RGB transformation matrix
  local r = 4.0767416621 * l3 - 3.3077115913 * m3 + 0.2309699292 * s3
  local g = -1.2684380046 * l3 + 2.6097574011 * m3 - 0.3413193965 * s3
  local b_out = -0.0041960863 * l3 - 0.7034186147 * m3 + 1.7076147010 * s3

  return r, g, b_out
end

local function linear_to_srgb_component(c)
  -- sRGB gamma correction (companding)
  -- Reference: IEC 61966-2-1:1999
  if c <= 0.0031308 then
    return c * 12.92 -- Linear segment
  else
    return 1.055 * (c ^ (1 / 2.4)) - 0.055 -- Power function (gamma ≈ 2.2)
  end
end

local function oklab_to_srgb(L, a, b)
  local r, g, b_comp = oklab_to_linear_rgb(L, a, b)

  r = linear_to_srgb_component(r)
  g = linear_to_srgb_component(g)
  b_comp = linear_to_srgb_component(b_comp)

  -- Clamp and convert to 8-bit
  r = math.floor(math.max(0, math.min(1, r)) * 255 + 0.5)
  g = math.floor(math.max(0, math.min(1, g)) * 255 + 0.5)
  b_comp = math.floor(math.max(0, math.min(1, b_comp)) * 255 + 0.5)

  return string.format('#%02x%02x%02x', r, g, b_comp)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- MONOTONE COLORS
-- ═══════════════════════════════════════════════════════════════════════════
local base03 = oklab_to_srgb(0.267337, -0.037339, -0.031128) -- #002b36
local base02 = oklab_to_srgb(0.309207, -0.039852, -0.033029) -- #073642
local base01 = oklab_to_srgb(0.523013, -0.021953, -0.017864) -- #586e75
local base00 = oklab_to_srgb(0.568165, -0.021219, -0.019038) -- #657b83

local base0 = oklab_to_srgb(0.71, -0.017838, -0.008417)
local base1 = oklab_to_srgb(0.697899, -0.015223, -0.004594) -- #93a1a1
local base2 = oklab_to_srgb(0.930609, -0.001091, 0.026010) -- #eee8d5
local base3 = oklab_to_srgb(0.973528, -0.000043, 0.026053) -- #fdf6e3

-- ═══════════════════════════════════════════════════════════════════════════
-- ACCENT COLORS
-- ═══════════════════════════════════════════════════════════════════════════
local yellow = oklab_to_srgb(0.654479, 0.010005, 0.133641) -- #b58900
local orange = oklab_to_srgb(0.63, 0.133661 * 0.69, 0.110183 * 0.69)
local red = oklab_to_srgb(0.63, 0.183749 * 0.72, 0.094099 * 0.72)
local magenta = oklab_to_srgb(0.592363, 0.201958, -0.014497) -- #d33682
local violet = oklab_to_srgb(0.582316, 0.019953, -0.124557) -- #6c71c4
local blue = oklab_to_srgb(0.614879, -0.059069, -0.126255) -- #268bd2
local cyan = oklab_to_srgb(0.643664, -0.101063, -0.013097) -- #2aa198
local green = oklab_to_srgb(0.644391, -0.072203, 0.132448) -- #859900

-- ═══════════════════════════════════════════════════════════════════════════
-- MODE SELECTION
-- ═══════════════════════════════════════════════════════════════════════════

-- Set to 'dark' or 'light'
local mode = vim.o.background or 'dark'

local colors = {}

if mode == 'dark' then
  -- Dark mode: dark background, light text
  colors.bg = base03
  colors.bg_highlight = base02
  colors.fg_comment = base01
  colors.fg = base0
  colors.fg_emphasis = base1
else
  colors.bg = base3
  colors.bg_highlight = base2
  colors.fg_comment = base1
  colors.fg = base00
  colors.fg_emphasis = base01
end

-- Accent colors are the same in both modes
colors.yellow = yellow
colors.orange = orange
colors.red = red
colors.magenta = magenta
colors.violet = violet
colors.blue = blue
colors.cyan = cyan
colors.green = green

colors.cursorline_bg = colors.bg_highlight
colors.selection_bg = base02
colors.visual_bg = base02

vim.g.colors_name = 'dicom'

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

local function blend(fg, t, target_bg)
  local a, b = hex_to_rgb(fg), hex_to_rgb(target_bg or colors.bg)
  local c = {
    math.floor(a[1] * (1 - t) + b[1] * t + 0.5),
    math.floor(a[2] * (1 - t) + b[2] * t + 0.5),
    math.floor(a[3] * (1 - t) + b[3] * t + 0.5),
  }
  return rgb_to_hex(c)
end

-- =============================================================================
-- Research-Driven Syntax Highlighting Strategy
-- Based on: Hannebauer et al. (2018), Tonsky (2025), Schloss (2023)
-- =============================================================================

-- 1. Core Editor Surface
h('Normal', { fg = colors.fg, bg = colors.bg })
h('EndOfBuffer', { fg = colors.bg })
h('CursorLine', { bg = colors.cursorline_bg })
h('CursorLineNr', { fg = colors.yellow, bold = true })
h('LineNr', { fg = colors.fg_comment })
h('WinSeparator', { fg = colors.bg_highlight, bg = colors.bg })

-- 2. Visual & Search (High Arousal)
h('Visual', { bg = colors.selection_bg })
h('Search', { fg = colors.bg, bg = colors.yellow })
h('IncSearch', { fg = colors.bg, bg = colors.orange })

h('Keyword', { fg = colors.green })
h('Statement', { fg = colors.green })
h('Conditional', { fg = colors.green })
h('Repeat', { fg = colors.green })

h('Function', { fg = colors.blue })

-- Types
h('Type', { fg = colors.yellow })
h('StorageClass', { fg = colors.yellow })
h('Structure', { fg = colors.yellow })
h('Typedef', { fg = colors.yellow })

-- Constants
h('Constant', { fg = colors.cyan })
h('String', { fg = colors.cyan })
h('Character', { fg = colors.cyan })
h('Number', { fg = colors.cyan })
h('Boolean', { fg = colors.cyan })
h('Float', { fg = colors.cyan })

-- PreProc
h('PreProc', { fg = colors.orange })
h('Include', { fg = colors.orange })
h('Define', { fg = colors.orange })
h('Macro', { fg = colors.orange })
h('PreCondit', { fg = colors.orange })

-- Special Characters - Cyan (escape/special)
h('Special', { fg = colors.cyan })

h('Identifier', { fg = colors.fg })
h('Variable', { fg = colors.fg })
h('Operator', { fg = colors.fg })

h('Delimiter', { fg = colors.fg })
h('NonText', { fg = colors.bg_highlight })

-- -----------------------------------------------------------------------------
-- Layer 6: COMMENTS
-- Luminance: L=comment (dimmest)
-- -----------------------------------------------------------------------------

h('Comment', { fg = colors.fg_comment, italic = true })

-- =============================================================================
-- 4. UI Components
-- =============================================================================

h('StatusLine', { bg = colors.fg, fg = colors.bg_highlight })
h('StatusLineNC', { fg = colors.fg_comment, bg = colors.bg_highlight, reverse = true })
h('WildMenu', { fg = colors.bg, bg = colors.blue })

-- Popup Menu
h('Pmenu', { fg = colors.fg, bg = colors.bg_highlight })
h('PmenuSel', { fg = colors.fg_emphasis, bg = colors.selection, reverse = true })
h('PmenuSbar', { bg = colors.bg_highlight })
h('PmenuThumb', { bg = colors.fg_comment })
h('PmenuMatch', { fg = colors.cyan, bold = true })
h('PmenuMatchSel', { bg = colors.selection, bold = true, fg = colors.fg_emphasis })

-- Float & Borders
h('NormalFloat', { bg = colors.bg_highlight })
h('FloatBorder', { fg = colors.comment })
h('Title', { fg = colors.orange, bold = true })

-- =============================================================================
-- 5. Diagnostics - Semantic Consistency
-- =============================================================================
--
-- Research basis (Schloss 2023):
--   Color-concept associations are universal:
--   Red → danger/anger (cross-cultural consistency)
--   Orange → warning/caution
--   Blue → information/calm
--   Cyan → hint/auxiliary
--
-- This mapping perfectly aligns with research! ✓
--

h('ErrorMsg', { fg = colors.red, bold = true })
h('WarningMsg', { fg = colors.orange })
h('ModeMsg', { fg = colors.cyan, bold = true })
h('Todo', { fg = colors.violet, bold = true, reverse = true })
h('MatchParen', { bg = colors.selection_bg, bold = true })

-- QuickFix & List
h('qfFileName', { fg = colors.blue })
h('qfLineNr', { fg = colors.cyan })
h('qfSeparator', { fg = colors.bg_highlight })
h('QuickFixLine', { bg = colors.cursorline_bg, bold = true })
h('qfText', { link = 'Normal' })

-- Underlined/Directory
h('Underlined', { fg = colors.violet, underline = true })
h('Directory', { fg = colors.blue })

-- sync to terminal
h('Magenta', { fg = colors.magenta })
h('Violet', { fg = colors.violet })

-- =============================================================================
-- 6. Treesitter Highlights (Optimized)
-- =============================================================================

-- Neutral Layer ⭐️ KEY OPTIMIZATION
h('@variable', { link = 'Identifier' }) -- Neutral
h('@variable.builtin', { link = '@variable' }) -- Neutral
h('@variable.parameter', { link = '@variable' }) -- Neutral
h('@variable.parameter.builtin', { link = '@variable.builtin' })
h('@variable.member', { link = '@variable' }) -- Neutral
h('@parameter', { fg = colors.fg }) -- Neutral
h('@property', { fg = colors.fg }) -- Neutral

-- Constants Layer ⭐️ OPTIMIZED
h('@constant', { fg = colors.cyan }) -- Constants = frozen
h('@constant.builtin', { fg = colors.cyan })
h('@constant.macro', { fg = colors.cyan })

-- Modules/Namespaces
h('@module', { link = 'Identifier' })
h('@module.builtin', { link = '@module' })

-- Labels
h('@label', { link = 'Label' })

-- Strings Layer
h('@string', { link = 'String' })
h('@string.documentation', { link = 'Comment' })
h('@string.regexp', { link = '@string' })
h('@string.escape', { link = 'Special' })
h('@string.special', { link = '@string' })
h('@string.special.symbol', { link = '@string' })
h('@string.special.path', { link = '@string' })
h('@string.special.url', { link = 'Underlined' })

h('@character', { link = 'String' })
h('@character.special', { link = '@character' })

-- Numbers Layer
h('@boolean', { link = 'Constant' })
h('@number', { link = 'Number' })
h('@number.float', { link = 'Float' })

-- Types Layer
h('@type', { link = 'Type' })
h('@type.builtin', { link = 'Type' })
h('@type.definition', { link = 'Type' })

-- Attributes/Decorators
h('@attribute', { link = 'Macro' })
h('@attribute.builtin', { link = 'Special' })

-- Functions Layer
h('@function', { link = 'Function' })
h('@function.builtin', { link = 'Function' })
h('@function.call', { link = '@function' })
h('@function.macro', { link = '@function' })
h('@function.method', { link = '@function' })
h('@function.method.call', { link = '@function' })
h('@constructor', { link = 'Function' })

-- Operators - Neutral
h('@operator', { link = 'Operator' })

-- Keywords Layer
h('@keyword', { link = 'Keyword' })
h('@keyword.coroutine', { link = '@keyword' })
h('@keyword.function', { link = 'Keyword' })
h('@keyword.operator', { link = '@keyword' })
h('@keyword.import', { link = 'PreProc' })
h('@keyword.type', { link = '@keyword' })
h('@keyword.modifier', { link = '@keyword' })
h('@keyword.repeat', { link = 'Repeat' })
h('@keyword.return', { link = '@keyword' })
h('@keyword.debug', { link = '@keyword' })
h('@keyword.exception', { link = '@keyword' })
h('@keyword.conditional', { link = 'Conditional' })
h('@keyword.conditional.ternary', { link = '@operator' })
h('@keyword.directive', { link = '@keyword' })
h('@keyword.directive.define', { link = '@keyword' })

-- Punctuation
h('@punctuation', { fg = colors.fg })
h('@punctuation.delimiter', { link = '@punctuation' })
h('@punctuation.bracket', { link = '@punctuation' })
h('@punctuation.special', { link = '@punctuation' })

-- Comments Layer
h('@comment', { link = 'Comment' })
h('@comment.documentation', { link = '@comment' })
h('@comment.error', { fg = colors.red, bold = true })
h('@comment.warning', { fg = colors.yellow, bold = true })
h('@comment.todo', { link = 'Special' })
h('@comment.note', { link = 'Special' })

-- Markup (Markdown, etc.)
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

-- Diff
h('@diff.plus', { fg = blend(colors.green, 0.5, colors.statusline_bg) })
h('@diff.minus', { fg = blend(colors.red, 0.5, colors.statusline_bg) })
h('@diff.delta', { fg = blend(colors.yellow, 0.5, colors.statusline_bg) })

-- HTML/XML
h('@tag', { fg = colors.green })
h('@tag.attribute', { fg = colors.fg })
h('@tag.delimiter', { fg = colors.fg })
h('@tag.builtin', { link = 'Special' })

-- Vimdoc Special Handling
h('@constant.comment', { link = 'SpecialComment' })
h('@number.comment', { link = 'Comment' })
h('@punctuation.bracket.comment', { link = 'SpecialComment' })
h('@punctuation.delimiter.comment', { link = 'SpecialComment' })
h('@label.vimdoc', { link = 'String' })
h('@markup.heading.1.delimiter.vimdoc', { link = '@markup.heading.1' })
h('@markup.heading.2.delimiter.vimdoc', { link = '@markup.heading.2' })

-- Semantic Aliases
h('@class', { fg = colors.yellow })
h('@method', { fg = colors.blue })
h('@interface', { fg = colors.yellow })
h('@namespace', { fg = colors.fg })

-- =============================================================================
-- 7. LSP Semantic Highlights
-- =============================================================================

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
h('@lsp.type.parameter', { fg = colors.fg })
h('@lsp.type.property', { fg = colors.fg })
h('@lsp.type.regexp', { link = '@string.regexp' })
h('@lsp.type.string', { link = '@string' })
h('@lsp.type.struct', { link = '@type' })
h('@lsp.type.type', { link = '@type' })
h('@lsp.type.typeParameter', { link = '@type.definition' })
h('@lsp.type.variable', { link = '@variable' })

-- LSP Modifiers
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

-- =============================================================================
-- 8. Diagnostics - Semantic Consistency (Schloss 2023)
-- =============================================================================

h('DiagnosticError', { fg = colors.red })
h('DiagnosticWarn', { fg = colors.yellow })
h('DiagnosticInfo', { fg = colors.blue })
h('DiagnosticHint', { fg = colors.cyan })

h('DiagnosticVirtualTextError', { bg = blend(colors.red, 0.4) })
h('DiagnosticVirtualTextWarn', { bg = blend(colors.yellow, 0.4) })
h('DiagnosticVirtualTextInfo', { bg = blend(colors.blue, 0.4) })
h('DiagnosticVirtualTextHint', { bg = blend(colors.cyan, 0.4) })

h('DiagnosticPrefixError', { fg = colors.red, bg = blend(colors.red, 0.25) })
h('DiagnosticPrefixWarn', { fg = colors.yellow, bg = blend(colors.yellow, 0.25) })
h('DiagnosticPrefixInfo', { fg = colors.blue, bg = blend(colors.blue, 0.25) })
h('DiagnosticPrefixHint', { fg = colors.cyan, bg = blend(colors.cyan, 0.25) })

h('DiagnosticUnderlineError', { undercurl = true, sp = colors.red })
h('DiagnosticUnderlineWarn', { undercurl = true, sp = colors.yellow })
h('DiagnosticUnderlineInfo', { undercurl = true, sp = colors.blue })
h('DiagnosticUnderlineHint', { undercurl = true, sp = colors.cyan })
h('YankHighlight', { fg = colors.bg, bg = colors.fg })

-- =============================================================================
-- 9. LSP & Other Plugin Support
-- =============================================================================

h('LspReferenceText', { bg = colors.selection_bg })
h('LspReferenceRead', { bg = colors.selection_bg })
h('LspReferenceWrite', { bg = colors.selection_bg })
h('LspReferenceTarget', { link = 'LspReferenceText' })
h('LspInlayHint', { link = 'NonText' })
h('LspCodeLens', { link = 'NonText' })
h('LspCodeLensSeparator', { link = 'NonText' })
h('LspSignatureActiveParameter', { link = 'LspReferenceText' })

-- Indentmini
h('IndentLine', { link = 'Comment' })
h('IndentLineCurrent', { link = 'Comment' })

-- GitSigns
h('GitSignsAdd', { fg = colors.green })
h('GitSignsChange', { fg = colors.orange })
h('GitSignsDelete', { fg = colors.red })

-- Dashboard
h('DashboardHeader', { fg = colors.green })
