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

local p = {
  bg = oklab_to_srgb(0.248, -0.002, 0.010),
  statusline_bg = oklab_to_srgb(0.205, -0.002, 0.012),
  normalfloat_bg = oklab_to_srgb(0.278, -0.002, 0.012),
  cursorline_bg = oklab_to_srgb(0.310, -0.002, 0.012),
  selection_bg = oklab_to_srgb(0.357, -0.002, 0.015),
  pmenu_bg = oklab_to_srgb(0.297, -0.002, 0.012),
  pmenu_thumb = oklab_to_srgb(0.369, 0.000, 0.014),
  pmenusel_bg = oklab_to_srgb(0.450, 0.000, 0.012),
  pmenusel_fg = oklab_to_srgb(0.148, 0.000, -0.006),

  fg = oklab_to_srgb(0.780, 0.000, 0.009),
  comment = oklab_to_srgb(0.528, -0.001, 0.007),
  linenr = oklab_to_srgb(0.432, -0.002, 0.006),
  linenr_active = oklab_to_srgb(0.719, -0.002, 0.007),

  yellow = oklab_to_srgb(0.749, 0.012, 0.052),
  orange = oklab_to_srgb(0.719, 0.022, 0.048),
  red = oklab_to_srgb(0.709, 0.042, 0.032),
  magenta = oklab_to_srgb(0.698, 0.038, -0.020),
  cyan = oklab_to_srgb(0.730, -0.055, -0.005),
  blue = oklab_to_srgb(0.698, -0.005, -0.025),
  green = oklab_to_srgb(0.730, -0.039, 0.068),
}

local d = {
  error = oklab_to_srgb(0.690, 0.085, 0.045),
  warn = oklab_to_srgb(0.760, 0.015, 0.100),
  info = oklab_to_srgb(0.710, -0.025, -0.030),
  hint = oklab_to_srgb(0.640, -0.002, 0.008),
}

vim.g.colors_name = 'eink'
vim.cmd('highlight clear')

local function hex_to_rgb(hex)
  if hex:sub(1, 1) == '#' then
    hex = hex:sub(2)
  end

  return {
    tonumber(hex:sub(1, 2), 16),
    tonumber(hex:sub(3, 4), 16),
    tonumber(hex:sub(5, 6), 16),
  }
end

local function find_oklab(target_hex)
  local tr, tg, tb = unpack(hex_to_rgb(target_hex))

  -- Grid search with refinement
  local best_L, best_a, best_b = 0, 0, 0
  local min_error = math.huge

  -- Coarse search
  for L = 0, 1, 0.01 do
    for a = -0.5, 0.5, 0.01 do
      for b = -0.5, 0.5, 0.01 do
        local result = oklab_to_srgb(L, a, b)
        local r, g, b_val = unpack(hex_to_rgb(result))
        local error = math.abs(r - tr) + math.abs(g - tg) + math.abs(b_val - tb)
        if error < min_error then
          min_error = error
          best_L, best_a, best_b = L, a, b
        end
      end
    end
  end

  -- Fine search around best
  local step = 0.001
  for L = best_L - 0.02, best_L + 0.02, step do
    for a = best_a - 0.02, best_a + 0.02, step do
      for b = best_b - 0.02, best_b + 0.02, step do
        local result = oklab_to_srgb(L, a, b)
        local r, g, b_val = unpack(hex_to_rgb(result))
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

vim.api.nvim_create_user_command('ColorOkLab', function()
  for k, v in pairs(p) do
    local L, a, b = find_oklab(v)
    print(
      string.format(
        '%s, %s -> Oklab(%.6f, %.6f, %.6f) -> %s',
        k,
        v,
        L,
        a,
        b,
        oklab_to_srgb(L, a, b)
      )
    )
  end
end, {})

local function rgb_to_hex(c)
  return string.format('#%02x%02x%02x', c[1], c[2], c[3])
end

local function blend(fg, t, target_bg)
  local a, b = hex_to_rgb(fg), hex_to_rgb(target_bg or p.bg)
  local c = {
    math.floor(a[1] * (1 - t) + b[1] * t + 0.5),
    math.floor(a[2] * (1 - t) + b[2] * t + 0.5),
    math.floor(a[3] * (1 - t) + b[3] * t + 0.5),
  }
  return rgb_to_hex(c)
end

local function h(group, properties)
  vim.api.nvim_set_hl(0, group, properties)
end

vim.api.nvim_create_user_command('ColorOutPut', function()
  for k, v in pairs(p) do
    print(('%s = "%s"'):format(k, v))
  end
end, {})

vim.api.nvim_create_user_command('RgbToOklab', function(args)
  print(oklab_to_srgb(unpack(args.fargs)))
end, { nargs = '+' })

h('Normal', { fg = p.fg, bg = p.bg })
h('EndOfBuffer', { fg = p.bg })
h('CursorLine', { bg = p.cursorline_bg })
h('LineNr', { fg = p.linenr })
h('CursorLineNr', { fg = p.linenr_active })
h('WinSeparator', { fg = p.statusline_bg, bg = p.bg })

-- 2. Visual & Search (High Arousal)
h('Visual', { bg = p.selection_bg })
h('Search', { fg = p.bg, bg = p.yellow })
h('IncSearch', { fg = p.bg, bg = p.orange })

h('Keyword', { fg = p.fg })
h('Statement', { fg = p.fg })
h('Repeat', { fg = p.fg })
h('Conditional', { link = 'Repeat' })

h('Function', { fg = p.green })

-- Types
h('Type', { fg = p.fg })
h('StorageClass', { fg = p.fg })
h('Structure', { fg = p.fg })
h('Typedef', { fg = p.fg })

-- Constants
h('Constant', { fg = p.magenta })
h('String', { fg = p.orange })
h('Character', { link = 'Constant' })
h('Number', { link = 'Constant' })
h('Boolean', { link = 'Constant' })
h('Float', { link = 'Constant' })

-- PreProc
h('Include', { fg = p.fg })
h('PreProc', { link = 'Include' })
h('Define', { link = 'Include' })
h('Macro', { link = 'Include' })
h('PreCondit', { link = 'Include' })

-- Special Characters - Cyan (escape/special)
h('Special', { fg = p.cyan })

h('Identifier', { fg = p.fg })
h('Variable', { fg = p.fg })
h('Operator', { fg = p.fg })

h('Delimiter', { fg = p.fg })
h('NonText', { fg = p.statusline_bg })

-- -----------------------------------------------------------------------------
-- Layer 6: COMMENTS
-- Luminance: L=comment (dimmest)
-- -----------------------------------------------------------------------------

h('Comment', { fg = p.comment, italic = true })

-- =============================================================================
-- 4. UI Components
-- =============================================================================

h('StatusLine', { bg = p.statusline_bg, fg = p.fg })
h('StatusLineNC', { bg = p.normalfloat_bg, fg = p.fg })
h('WildMenu', { fg = p.bg, bg = p.blue })
h('ColorColumn', { bg = p.cursorline_bg })

-- Popup Menu
h('Pmenu', { fg = p.fg, bg = p.pmenu_bg })
h('PmenuSel', { bg = p.blue, fg = p.pmenusel_fg })
h('PmenuSbar', { bg = p.statusline_bg })
h('PmenuThumb', { bg = p.pmenu_thumb })
-- h('PmenuMatch', { fg = p.cyan, bold = true })
-- h('PmenuMatchSel', { fg = p.cyan })

-- Float & Borders
h('NormalFloat', { bg = p.normalfloat_bg })
h('FloatBorder', { fg = p.comment })
h('PmenuBorder', { bg = 'None', fg = p.comment })
h('Title', { fg = p.fg, bold = true })

h('ErrorMsg', { fg = p.red, bold = true })
h('WarningMsg', { fg = p.orange })
h('ModeMsg', { fg = p.cyan, bold = true })
h('Todo', { fg = p.violet, bold = true, reverse = true })
h('MatchParen', { bg = p.selection_bg, bold = true })

-- QuickFix & List
h('qfFileName', { fg = p.blue })
h('qfLineNr', { fg = p.cyan })
h('qfSeparator', { fg = p.statusline_bg })
h('QuickFixLine', { bg = p.cursorline_bg, bold = true })
h('qfText', { link = 'Normal' })

-- Underlined/Directory
h('Underlined', { fg = p.violet, underline = true })
h('Directory', { fg = p.blue })

-- sync to terminal
h('Magenta', { fg = p.magenta })
h('Violet', { fg = p.violet })

-- =============================================================================
-- 6. Treesitter Highlights (Optimized)
-- =============================================================================

-- Neutral Layer ⭐️ KEY OPTIMIZATION
h('@variable', { link = 'Identifier' }) -- Neutral
h('@variable.builtin', { link = '@variable' }) -- Neutral
h('@variable.parameter', { link = '@variable' }) -- Neutral
h('@variable.parameter.builtin', { link = '@variable.builtin' })
h('@variable.member', { link = '@variable' }) -- Neutral
h('@parameter', { fg = p.fg }) -- Neutral
h('@property', { fg = p.fg }) -- Neutral

-- Constants Layer ⭐️ OPTIMIZED
h('@constant', { link = 'Constant' }) -- Constants = frozen
h('@constant.builtin', { link = '@constant' })
h('@constant.macro', { link = '@constant' })

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
h('@punctuation', { fg = p.fg })
h('@punctuation.delimiter', { link = '@punctuation' })
h('@punctuation.bracket', { link = '@punctuation' })
h('@punctuation.special', { link = '@punctuation' })

-- Comments Layer
h('@comment', { link = 'Comment' })
h('@comment.documentation', { link = '@comment' })
h('@comment.error', { fg = p.red, bold = true })
h('@comment.warning', { fg = p.yellow, bold = true })
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
h('@markup.list.checked', { fg = p.green })
h('@markup.list.unchecked', { link = '@markup.list' })

-- Diff
h('@diff.plus', { fg = blend(p.green, 0.5, p.statusline_bg) })
h('@diff.minus', { fg = blend(p.red, 0.5, p.statusline_bg) })
h('@diff.delta', { fg = blend(p.yellow, 0.5, p.statusline_bg) })

-- HTML/XML
h('@tag', { fg = p.green })
h('@tag.attribute', { fg = p.fg })
h('@tag.delimiter', { fg = p.fg })
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
h('@class', { fg = p.yellow })
h('@method', { fg = p.blue })
h('@interface', { fg = p.yellow })
h('@namespace', { fg = p.fg })

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
h('@lsp.type.parameter', { fg = p.fg })
h('@lsp.type.property', { fg = p.fg })
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

h('DiagnosticError', { fg = d.error })
h('DiagnosticWarn', { fg = d.warn })
h('DiagnosticInfo', { fg = d.info })
h('DiagnosticHint', { fg = d.hint })

h('DiagnosticVirtualTextError', { bg = blend(d.error, 0.4) })
h('DiagnosticVirtualTextWarn', { bg = blend(d.warn, 0.4) })
h('DiagnosticVirtualTextInfo', { bg = blend(d.info, 0.4) })
h('DiagnosticVirtualTextHint', { bg = blend(d.hint, 0.4) })

h('DiagnosticPrefixError', { fg = d.red, bg = blend(d.error, 0.25) })
h('DiagnosticPrefixWarn', { fg = d.warn, bg = blend(d.warn, 0.25) })
h('DiagnosticPrefixInfo', { fg = d.info, bg = blend(d.info, 0.25) })
h('DiagnosticPrefixHint', { fg = d.hint, bg = blend(d.hint, 0.25) })

h('DiagnosticUnderlineError', { undercurl = true, sp = d.error })
h('DiagnosticUnderlineWarn', { undercurl = true, sp = d.warn })
h('DiagnosticUnderlineInfo', { undercurl = true, sp = d.info })
h('DiagnosticUnderlineHint', { undercurl = true, sp = d.hint })
h('YankHighlight', { fg = p.bg, bg = p.fg })

-- =============================================================================
-- 9. LSP & Other Plugin Support
-- =============================================================================

h('LspReferenceText', { bg = p.selection_bg })
h('LspReferenceRead', { bg = p.selection_bg })
h('LspReferenceWrite', { bg = p.selection_bg })
h('LspReferenceTarget', { link = 'LspReferenceText' })
h('LspInlayHint', { link = 'NonText' })
h('LspCodeLens', { link = 'NonText' })
h('LspCodeLensSeparator', { link = 'NonText' })
h('LspSignatureActiveParameter', { link = 'LspReferenceText' })

-- Indentmini
h('IndentLine', { link = 'Comment' })
h('IndentLineCurrent', { link = 'Comment' })

-- GitSigns
h('GitSignsAdd', { fg = p.green })
h('GitSignsChange', { fg = p.orange })
h('GitSignsDelete', { fg = p.red })

-- Dashboard
h('DashboardHeader', { fg = p.green })
