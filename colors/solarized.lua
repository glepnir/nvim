local function oklab_to_linear_rgb(L, a, b)
  -- Oklab to LMS conversion
  -- Reference: Björn Ottosson, "A perceptual color space for image processing"
  local l = L + 0.3963377774 * a + 0.2158037573 * b
  local m = L - 0.1055613458 * a - 0.0638541728 * b
  local s = L - 0.0894841775 * a - 1.2914855480 * b

  local l3, m3, s3 = l * l * l, m * m * m, s * s * s

  local r = 4.0767416621 * l3 - 3.3077115913 * m3 + 0.2309699292 * s3
  local g = -1.2684380046 * l3 + 2.6097574011 * m3 - 0.3413193965 * s3
  local b_out = -0.0041960863 * l3 - 0.7034186147 * m3 + 1.7076147010 * s3

  return r, g, b_out
end

local function linear_to_srgb_component(c)
  -- sRGB gamma correction (companding)
  -- Reference: IEC 61966-2-1:1999
  if c <= 0.0031308 then
    return c * 12.92
  else
    return 1.055 * (c ^ (1 / 2.4)) - 0.055
  end
end

local function oklab_to_srgb(L, a, b)
  local r, g, b_comp = oklab_to_linear_rgb(L, a, b)

  r = linear_to_srgb_component(r)
  g = linear_to_srgb_component(g)
  b_comp = linear_to_srgb_component(b_comp)

  r = math.floor(math.max(0, math.min(1, r)) * 255 + 0.5)
  g = math.floor(math.max(0, math.min(1, g)) * 255 + 0.5)
  b_comp = math.floor(math.max(0, math.min(1, b_comp)) * 255 + 0.5)

  return string.format('#%02x%02x%02x', r, g, b_comp)
end

local function _hex_to_rgb(hex)
  return tonumber(hex:sub(2, 3), 16), tonumber(hex:sub(4, 5), 16), tonumber(hex:sub(6, 7), 16)
end

local function find_oklab(target_hex)
  print(vim.inspect(target_hex))
  local tr, tg, tb = _hex_to_rgb(target_hex)

  local best_L, best_a, best_b = 0, 0, 0
  local min_error = math.huge

  for L = 0, 1, 0.01 do
    for a = -0.5, 0.5, 0.01 do
      for b = -0.5, 0.5, 0.01 do
        local result = oklab_to_srgb(L, a, b)
        local r, g, b_val = _hex_to_rgb(result)
        local error = math.abs(r - tr) + math.abs(g - tg) + math.abs(b_val - tb)
        if error < min_error then
          min_error = error
          best_L, best_a, best_b = L, a, b
        end
      end
    end
  end

  local step = 0.001
  for L = best_L - 0.02, best_L + 0.02, step do
    for a = best_a - 0.02, best_a + 0.02, step do
      for b = best_b - 0.02, best_b + 0.02, step do
        local result = oklab_to_srgb(L, a, b)
        local r, g, b_val = _hex_to_rgb(result)
        local error = math.abs(r - tr) + math.abs(g - tg) + math.abs(b_val - tb)
        if error < min_error then
          min_error = error
          best_L, best_a, best_b = L, a, b
        end
      end
    end
  end

  return best_L, best_a, best_b
end

vim.api.nvim_create_user_command('HexToOKLAB', function(opt)
  local L, a, b = find_oklab(opt.args)
  print(
    string.format('%s -> Oklab(%.6f, %.6f, %.6f) -> %s', opt.args, L, a, b, oklab_to_srgb(L, a, b))
  )
end, { nargs = 1 })

-- ═══════════════════════════════════════════════════════════════════════════
-- MONOTONE COLORS
-- ═══════════════════════════════════════════════════════════════════════════
local base05 = oklab_to_srgb(0.240000, -0.036000, -0.030000)
-- local base04 = oklab_to_srgb(0.423013, -0.021953, -0.017864)
local base03 = oklab_to_srgb(0.267337, -0.037339, -0.031128) -- editor bg

-- L ：bg(0.267) → cursorline(0.298) → pmenu/sel(0.322) → float/pmenusel(0.358)
local base_cursorline = oklab_to_srgb(0.298000, -0.038000, -0.031500)
local base02 = oklab_to_srgb(0.322000, -0.038500, -0.032000)
-- local base_float = oklab_to_srgb(0.358000, -0.037000, -0.029000)
--
-- local base01 = oklab_to_srgb(0.523013, -0.021953, -0.017864)
-- local base00 = oklab_to_srgb(0.568165, -0.021219, -0.019038)
--
-- local base0 = oklab_to_srgb(0.709236, -0.023223, -0.013451)
-- local base1 = oklab_to_srgb(0.697899, -0.015223, -0.004594)
-- local base2 = oklab_to_srgb(0.930609, -0.001091, 0.026010)
-- local base3 = oklab_to_srgb(0.973528, -0.000043, 0.026053)

-- ═══════════════════════════════════════════════════════════════════════════
-- ACCENT COLORS
-- ═══════════════════════════════════════════════════════════════════════════
-- local yellow = oklab_to_srgb(0.654479, 0.010005, 0.133641)
-- local orange = oklab_to_srgb(0.63, 0.133661 * 0.69, 0.110183 * 0.69)
-- local red = oklab_to_srgb(0.60, 0.183749 * 0.55, 0.094099 * 0.55)
-- local magenta = oklab_to_srgb(0.592363, 0.201958, -0.014497)
-- local violet = oklab_to_srgb(0.582316, 0.019953, -0.124557)
-- local blue = oklab_to_srgb(0.614879, -0.059069, -0.126255)
-- local cyan = oklab_to_srgb(0.643664, -0.101063, -0.013097)
-- local green = oklab_to_srgb(0.644391, -0.072203, 0.132448)

-- ═══════════════════════════════════════════════════════════════════════════
-- STATUSLINE MUTED VARIANTS
-- ═══════════════════════════════════════════════════════════════════════════
-- local sl_diag_error = oklab_to_srgb(0.480, 0.118, 0.058)
-- local sl_diag_warn = oklab_to_srgb(0.510, 0.009, 0.118)
-- local sl_diag_info = oklab_to_srgb(0.500, -0.050, -0.108)
-- local sl_diag_hint = oklab_to_srgb(0.500, -0.088, -0.014)

-- ══════════════════════════════════════════════════════════════════════
local base04 = oklab_to_srgb(0.423013, -0.020000, -0.008000)
-- local base03 = oklab_to_srgb(0.347000, -0.024000, -0.004000)

-- bg(0.267) → cursorline(0.297) → pmenu_sel(0.327) → float(0.357)
-- local base_cursorline = oklab_to_srgb(0.297000, -0.030000, -0.006000)
-- local base02 = oklab_to_srgb(0.327000, -0.030000, -0.007000)
local base_float = oklab_to_srgb(0.357000, -0.029000, -0.006000)

local base01 = oklab_to_srgb(0.523013, -0.020000, -0.010000)
local base00 = oklab_to_srgb(0.568165, -0.019000, -0.010000)

local base0 = oklab_to_srgb(0.702000, -0.016000, -0.005000)
local base1 = oklab_to_srgb(0.698000, -0.014000, -0.002000)
local base2 = oklab_to_srgb(0.930609, -0.001000, 0.026000)
local base3 = oklab_to_srgb(0.973528, 0.000000, 0.026000)

-- ──────────────────────────────────────────────────────────────────────
local yellow = oklab_to_srgb(0.654000, 0.010000, 0.134000)
local red = oklab_to_srgb(0.610000, 0.118000, 0.030000) -- hue ≈ 14°
local orange = oklab_to_srgb(0.635000, 0.082000, 0.090000) -- hue ≈ 48°
local magenta = oklab_to_srgb(0.600000, 0.124000, -0.009000) -- C ≈ 0.124

local blue = oklab_to_srgb(0.630000, -0.047000, -0.101000)
local violet = oklab_to_srgb(0.597000, 0.016000, -0.100000)
local cyan = oklab_to_srgb(0.643664, -0.101063, -0.013097)
-- local cyan = oklab_to_srgb(0.643664, -0.086000, 0.005000)
local green = oklab_to_srgb(0.648000, -0.068000, 0.125000)

local sl_diag_error = oklab_to_srgb(0.490000, 0.115000, 0.055000)
local sl_diag_warn = oklab_to_srgb(0.520000, 0.008000, 0.115000)
local sl_diag_info = oklab_to_srgb(0.510000, -0.040000, -0.086000)
local sl_diag_hint = oklab_to_srgb(0.510000, -0.070000, -0.011000)

-- ═══════════════════════════════════════════════════════════════════════════
-- MODE SELECTION
-- ═══════════════════════════════════════════════════════════════════════════
local mode = vim.o.background or 'dark'
local colors = {}

if mode == 'dark' then
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

colors.yellow = yellow
colors.orange = orange
colors.red = red
colors.magenta = magenta
colors.violet = violet
colors.blue = blue
colors.cyan = cyan
colors.green = green

colors.cursorline_bg = base_cursorline
colors.float_bg = base_float
colors.selection_bg = base02
colors.statusline_bg = oklab_to_srgb(0.440, -0.022, -0.010)
colors.visual_bg = base02

vim.g.colors_name = 'solarized'

vim.api.nvim_create_user_command('ColorOutPut', function()
  for k, v in pairs(colors) do
    print(('%s = "%s"'):format(k, v))
  end
end, {})

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
-- 1. Core Editor Surface
-- =============================================================================
h('Normal', { fg = colors.fg, bg = colors.bg })
h('EndOfBuffer', { fg = colors.bg })
h('CursorLine', { bg = colors.cursorline_bg })
h('CursorLineNr', { fg = colors.base1, bold = true })
h('LineNr', { fg = colors.fg_comment })
h('WinSeparator', { fg = colors.bg_highlight, bg = colors.bg })

-- =============================================================================
-- 2. Visual & Search
-- =============================================================================
h('Visual', { bg = colors.selection_bg })
h('Search', { fg = colors.bg, bg = colors.yellow })
h('IncSearch', { fg = colors.bg, bg = colors.orange })

-- =============================================================================
-- 3. Syntax
-- =============================================================================
h('Keyword', { fg = colors.green })
h('Statement', { fg = colors.green })
h('Conditional', { fg = colors.green })
h('Repeat', { fg = colors.green })

h('Function', { fg = colors.blue })

h('Type', { fg = colors.yellow })
h('StorageClass', { fg = colors.yellow })
h('Structure', { fg = colors.yellow })
h('Typedef', { fg = colors.yellow })

h('Constant', { fg = colors.cyan })
h('String', { fg = colors.cyan })
h('Character', { fg = colors.cyan })
h('Number', { fg = colors.cyan })
h('Boolean', { fg = colors.cyan })
h('Float', { fg = colors.cyan })

h('PreProc', { fg = colors.orange })
h('Include', { fg = colors.orange })
h('Define', { fg = colors.orange })
h('Macro', { fg = colors.orange })
h('PreCondit', { fg = colors.orange })

h('Special', { fg = colors.cyan })

h('Identifier', { fg = colors.fg })
h('Variable', { fg = colors.fg })
h('Operator', { fg = colors.fg })
h('Delimiter', { fg = colors.fg })
h('NonText', { fg = colors.bg_highlight })

h('Comment', { fg = colors.fg_comment, italic = true })

-- =============================================================================
-- 4. UI Components
-- =============================================================================
h('StatusLine', { bg = base1, fg = colors.bg_highlight })
h('StatusLineNC', { bg = colors.fg_comment, fg = colors.bg_highlight })
h('WildMenu', { fg = colors.bg, bg = colors.blue })
h('ColorColumn', { bg = colors.bg_highlight })
h('WhiteSpace', { fg = base04 })

-- ─────────────────────────────────────────────────────────────────────────────
-- Popup Menu
h('Pmenu', { fg = colors.fg, bg = base02 })
h('PmenuSel', { fg = colors.bg, bg = colors.fg })
h('PmenuSbar', { bg = base02 })
h('PmenuThumb', { bg = base01 })
-- h('PmenuMatch', { fg = colors.blue, bold = true })
-- h('PmenuMatchSel', { fg = colors.blue, bold = true })
h('PmenuBorder', { fg = colors.fg_comment })

-- ─────────────────────────────────────────────────────────────────────────────
-- Float & Borders
-- NormalFloat 用 base05 (L≈0.240)，比 editor bg (L≈0.267) 更暗，沉入感
-- ─────────────────────────────────────────────────────────────────────────────
h('NormalFloat', { bg = base05 })
h('FloatBorder', { fg = blend(colors.fg_comment, 0.40) })
h('Title', { fg = colors.bg_highlight, bold = true })

-- =============================================================================
-- 5. Messages & Misc
-- =============================================================================
h('ErrorMsg', { fg = colors.red, bold = true })
h('WarningMsg', { fg = colors.orange })
h('ModeMsg', { fg = colors.cyan, bold = true })
h('Todo', { fg = colors.violet, bold = true, reverse = true })
h('MatchParen', { bg = colors.selection_bg, bold = true })

h('qfFileName', { fg = colors.blue })
h('qfLineNr', { fg = colors.cyan })
h('qfSeparator', { fg = colors.bg_highlight })
h('QuickFixLine', { bg = colors.cursorline_bg, bold = true })
h('qfText', { link = 'Normal' })

h('Underlined', { fg = colors.violet, underline = true })
h('Directory', { fg = colors.blue })

h('Magenta', { fg = colors.magenta })
h('Violet', { fg = colors.violet })

-- =============================================================================
-- 6. Treesitter Highlights
-- =============================================================================
h('@variable', { link = 'Identifier' })
h('@variable.builtin', { link = '@variable' })
h('@variable.parameter', { link = '@variable' })
h('@variable.parameter.builtin', { link = '@variable.builtin' })
h('@variable.member', { link = '@variable' })
h('@parameter', { fg = colors.fg })
h('@property', { fg = colors.fg })

h('@constant', { fg = colors.cyan })
h('@constant.builtin', { fg = colors.cyan })
h('@constant.macro', { fg = colors.cyan })

h('@module', { link = 'Identifier' })
h('@module.builtin', { link = '@module' })

h('@label', { link = 'Label' })

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

h('@boolean', { link = 'Constant' })
h('@number', { link = 'Number' })
h('@number.float', { link = 'Float' })

h('@type', { link = 'Type' })
h('@type.builtin', { link = 'Type' })
h('@type.definition', { link = 'Type' })

h('@attribute', { link = 'Macro' })
h('@attribute.builtin', { link = 'Special' })

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

-- ─────────────────────────────────────────────────────────────────────────────
-- Diff
-- ─────────────────────────────────────────────────────────────────────────────
h('@diff.plus', { fg = oklab_to_srgb(0.490, -0.080, 0.115) })
h('@diff.minus', { fg = oklab_to_srgb(0.480, 0.118, 0.055) })
h('@diff.delta', { fg = oklab_to_srgb(0.500, 0.085, 0.095) })

h('@tag', { fg = colors.green })
h('@tag.attribute', { fg = colors.fg })
h('@tag.delimiter', { fg = colors.fg })
h('@tag.builtin', { link = 'Special' })

h('@constant.comment', { link = 'SpecialComment' })
h('@number.comment', { link = 'Comment' })
h('@punctuation.bracket.comment', { link = 'SpecialComment' })
h('@punctuation.delimiter.comment', { link = 'SpecialComment' })
h('@label.vimdoc', { link = 'String' })
h('@markup.heading.1.delimiter.vimdoc', { link = '@markup.heading.1' })
h('@markup.heading.2.delimiter.vimdoc', { link = '@markup.heading.2' })

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
-- 8. Diagnostics
-- =============================================================================

-- 编辑器内（暗背景，正常亮度）
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

-- ─────────────────────────────────────────────────────────────────────────────
-- Statusline diagnostic
-- ─────────────────────────────────────────────────────────────────────────────
h('DiagnosticERROR', { fg = sl_diag_error })
h('DiagnosticWARN', { fg = sl_diag_warn })
h('DiagnosticINFO', { fg = sl_diag_info })
h('DiagnosticHINT', { fg = sl_diag_hint })

-- =============================================================================
-- 9. LSP & Plugin Support
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
