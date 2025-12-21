local colors = {
  base04 = '#00202b',
  base03 = '#002838',
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
  green = '#87a828', -- L=64.4, C=64.8, Contrast=5.63
  magenta = '#d33682',
  fg = '#a8a8a8',
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

-- ============================================================================
-- Scientific Color Analysis Functions
-- ============================================================================
local function relative_luminance(hex)
  local rgb = hex_to_rgb(hex)
  local function adjust(c)
    c = c / 255
    return c <= 0.03928 and c / 12.92 or math.pow((c + 0.055) / 1.055, 2.4)
  end
  return 0.2126 * adjust(rgb[1]) + 0.7152 * adjust(rgb[2]) + 0.0722 * adjust(rgb[3])
end

local function contrast_ratio(fg, bg)
  local l1 = relative_luminance(fg)
  local l2 = relative_luminance(bg)
  local lighter = math.max(l1, l2)
  local darker = math.min(l1, l2)
  return (lighter + 0.05) / (darker + 0.05)
end

local function rgb_to_xyz(hex)
  local rgb = hex_to_rgb(hex)
  local function linearize(c)
    c = c / 255
    return c <= 0.04045 and c / 12.92 or math.pow((c + 0.055) / 1.055, 2.4)
  end
  local r, g, b = linearize(rgb[1]), linearize(rgb[2]), linearize(rgb[3])
  return {
    x = r * 0.4124564 + g * 0.3575761 + b * 0.1804375,
    y = r * 0.2126729 + g * 0.7151522 + b * 0.0721750,
    z = r * 0.0193339 + g * 0.1191920 + b * 0.9503041,
  }
end

local function xyz_to_lab(xyz)
  local Xn, Yn, Zn = 0.95047, 1.00000, 1.08883
  local x, y, z = xyz.x / Xn, xyz.y / Yn, xyz.z / Zn
  local delta = 6.0 / 29.0
  local function f(t)
    return t > delta ^ 3 and t ^ (1 / 3) or t / (3 * delta ^ 2) + 4 / 29
  end
  local fx, fy, fz = f(x), f(y), f(z)
  return {
    L = 116 * fy - 16,
    a = 500 * (fx - fy),
    b = 200 * (fy - fz),
  }
end

local function lab_to_lch(lab)
  local C = math.sqrt(lab.a ^ 2 + lab.b ^ 2)
  local H = math.atan2(lab.b, lab.a) * 180 / math.pi
  if H < 0 then
    H = H + 360
  end
  return { L = lab.L, C = C, H = H }
end

local function rgb_to_lch(hex)
  return lab_to_lch(xyz_to_lab(rgb_to_xyz(hex)))
end

local function lch_to_lab(lch)
  local h_rad = lch.H * math.pi / 180
  return {
    L = lch.L,
    a = lch.C * math.cos(h_rad),
    b = lch.C * math.sin(h_rad),
  }
end

local function lab_to_xyz(lab)
  local Xn, Yn, Zn = 0.95047, 1.00000, 1.08883
  local fy = (lab.L + 16) / 116
  local fx = lab.a / 500 + fy
  local fz = fy - lab.b / 200
  local delta = 6.0 / 29.0
  local function finv(t)
    return t > delta and t ^ 3 or 3 * delta ^ 2 * (t - 4 / 29)
  end
  return {
    x = Xn * finv(fx),
    y = Yn * finv(fy),
    z = Zn * finv(fz),
  }
end

local function xyz_to_rgb(xyz)
  local r = xyz.x * 3.2404542 + xyz.y * -1.5371385 + xyz.z * -0.4985314
  local g = xyz.x * -0.9692660 + xyz.y * 1.8760108 + xyz.z * 0.0415560
  local b = xyz.x * 0.0556434 + xyz.y * -0.2040259 + xyz.z * 1.0572252
  local function gamma(c)
    return c <= 0.0031308 and c * 12.92 or 1.055 * c ^ (1 / 2.4) - 0.055
  end
  local function clamp(c)
    return math.max(0, math.min(255, math.floor(gamma(c) * 255 + 0.5)))
  end
  return { clamp(r), clamp(g), clamp(b) }
end

local function lch_to_rgb(lch)
  return rgb_to_hex(xyz_to_rgb(lab_to_xyz(lch_to_lab(lch))))
end

-- ============================================================================
-- Detailed Color Testing
-- ============================================================================
local function test_color_detailed(hex)
  local results = {}

  if not hex:match('^#[0-9a-fA-F]+$') then
    return { 'Error: Invalid hex format. Use #rrggbb (e.g., #84a800)' }
  end

  table.insert(results, string.format('=== Color Analysis: %s ===', hex))
  table.insert(results, '')

  -- LCH analysis
  local lch = rgb_to_lch(hex)
  local contrast = contrast_ratio(hex, colors.base03)

  -- Detect if this is a neutral gray (C ≈ 0)
  local is_gray = lch.C < 5

  table.insert(results, 'LCH Color Space Values:')
  table.insert(results, string.format('  Lightness (L): %.1f', lch.L))
  table.insert(results, string.format('    - 0 = black, 100 = white'))

  if is_gray then
    table.insert(results, string.format('    - For normal text: 65-75 recommended'))
  else
    table.insert(results, string.format('    - For syntax colors: 55-65 recommended'))
  end

  table.insert(results, string.format('  Chroma (C):    %.1f', lch.C))
  table.insert(results, string.format('    - 0 = gray, higher = more saturated'))

  if is_gray then
    table.insert(results, string.format('    - This is a neutral gray (C≈0) ✓'))
  else
    table.insert(results, string.format('    - Recommended: 40-70 (moderate)'))
  end

  table.insert(results, string.format('  Hue (H):       %.1f°', lch.H))
  if not is_gray then
    table.insert(results, string.format('    - 0°=red, 90°=yellow, 180°=green, 270°=blue'))
  else
    table.insert(results, string.format('    - (Hue irrelevant for neutral gray)'))
  end
  table.insert(results, '')

  -- Contrast analysis
  table.insert(results, string.format('WCAG Contrast vs background (%s):', colors.base03))
  table.insert(results, string.format('  Ratio: %.2f:1', contrast))
  table.insert(
    results,
    string.format('  Level AA (≥4.5:1):  %s', contrast >= 4.5 and '✓ PASS' or '✗ FAIL')
  )
  table.insert(
    results,
    string.format('  Level AAA (≥7:1):   %s', contrast >= 7 and '✓ PASS' or '✗ FAIL')
  )
  table.insert(
    results,
    string.format(
      '  Comfortable (4.5-6.5): %s',
      contrast >= 4.5 and contrast <= 6.5 and '✓ Yes' or '~ Outside range'
    )
  )
  table.insert(results, '')

  -- Ergonomic assessment
  table.insert(results, 'Ergonomic Assessment:')

  if is_gray then
    -- For normal text (gray)
    local L_ok = lch.L >= 65 and lch.L <= 75
    table.insert(results, string.format('  Type: Normal text (neutral gray)'))
    table.insert(
      results,
      string.format(
        '  Lightness: %s',
        L_ok and '✓ Optimal for body text'
          or lch.L < 65 and '⚠ Too dark for extended reading'
          or '⚠ Too bright (may cause glare)'
      )
    )
    table.insert(results, string.format('  Saturation: ✓ Neutral (correct for text)'))
  else
    -- For syntax colors
    local L_ok = lch.L >= 55 and lch.L <= 65
    local C_ok = lch.C >= 40 and lch.C <= 70

    table.insert(results, string.format('  Type: Syntax highlight color'))
    table.insert(
      results,
      string.format(
        '  Lightness: %s',
        L_ok and '✓ Optimal' or lch.L < 55 and '⚠ Too dark' or '⚠ Too bright'
      )
    )
    table.insert(
      results,
      string.format(
        '  Saturation: %s',
        C_ok and '✓ Moderate' or lch.C < 40 and '⚠ Low (washed out)' or '⚠ High (fatiguing)'
      )
    )
  end
  table.insert(results, '')

  -- Optimization suggestion - FIXED LOGIC
  local needs_optimization = false

  if is_gray then
    if lch.L < 65 or lch.L > 75 or contrast < 4.5 or contrast > 6.5 then
      needs_optimization = true
    end
  else
    -- Need optimization if:
    -- 1. L or C out of range, OR
    -- 2. Contrast too low (< 4.5), OR
    -- 3. Contrast too high (> 6.5)
    local L_ok = lch.L >= 55 and lch.L <= 65
    local C_ok = lch.C >= 40 and lch.C <= 70
    local contrast_ok = contrast >= 4.5 and contrast <= 6.5

    if not (L_ok and C_ok and contrast_ok) then
      needs_optimization = true
    end
  end

  if needs_optimization then
    table.insert(results, '【Optimization Suggestion】')

    if is_gray then
      -- For gray, only adjust L
      local opt_L = math.max(65, math.min(75, lch.L))
      if lch.L < 65 then
        opt_L = 68
      elseif lch.L > 75 then
        opt_L = 72
      end

      -- Adjust L for contrast
      if contrast < 4.5 then
        -- Increase L to achieve 4.5:1 contrast
        for test_L = opt_L, 85, 0.5 do
          local test_val = math.floor((test_L / 100) * 255 + 0.5)
          local test_hex = string.format('#%02x%02x%02x', test_val, test_val, test_val)
          if contrast_ratio(test_hex, colors.base03) >= 4.5 then
            opt_L = test_L
            break
          end
        end
      end

      local opt_lch = { L = opt_L, C = 0, H = 0 }
      local opt_val = math.floor((opt_lch.L / 100) * 255 + 0.5)
      local opt_hex = string.format('#%02x%02x%02x', opt_val, opt_val, opt_val)
      local opt_contrast = contrast_ratio(opt_hex, colors.base03)

      table.insert(results, string.format('  Suggested: %s (neutral gray)', opt_hex))
      table.insert(
        results,
        string.format(
          '  Changes:   L: %.1f→%.1f (C and H preserved as neutral)',
          lch.L,
          opt_lch.L
        )
      )
      table.insert(results, string.format('  Contrast:  %.2f→%.2f:1', contrast, opt_contrast))
    else
      -- For colors, adjust L and C
      local opt_L = lch.L
      local opt_C = lch.C

      -- Step 1: Adjust L to target range
      if lch.L < 55 then
        opt_L = 58
      elseif lch.L > 65 then
        opt_L = 62
      end

      -- Step 2: Adjust C to target range
      if lch.C < 40 then
        opt_C = 50
      elseif lch.C > 70 then
        opt_C = 60
      end

      -- Step 3: CRITICAL - Ensure minimum contrast of 4.5:1
      if contrast < 4.5 then
        -- Binary search for minimum L that achieves 4.5:1
        local low, high = opt_L, 75
        for _ = 1, 30 do
          local mid = (low + high) / 2
          local test_lch = { L = mid, C = opt_C, H = lch.H }
          local test_hex = lch_to_rgb(test_lch)
          local test_contrast = contrast_ratio(test_hex, colors.base03)

          if test_contrast >= 4.5 then
            opt_L = mid
            high = mid - 0.1
          else
            low = mid + 0.1
          end
        end
      elseif contrast > 6.5 then
        -- Too bright, reduce L slightly
        opt_L = opt_L * 0.95
      end

      local opt_lch = {
        L = opt_L,
        C = opt_C,
        H = lch.H,
      }

      local opt_hex = lch_to_rgb(opt_lch)
      local opt_contrast = contrast_ratio(opt_hex, colors.base03)

      table.insert(results, string.format('  Suggested: %s', opt_hex))
      table.insert(
        results,
        string.format(
          '  Changes:   L: %.1f→%.1f  C: %.1f→%.1f  H: %.1f° (preserved)',
          lch.L,
          opt_lch.L,
          lch.C,
          opt_lch.C,
          lch.H
        )
      )
      table.insert(results, string.format('  Contrast:  %.2f→%.2f:1', contrast, opt_contrast))
    end
    table.insert(results, '')
  else
    table.insert(results, '✓ Color is already well-optimized!')
    table.insert(results, '')
  end

  -- RGB breakdown
  local rgb = hex_to_rgb(hex)
  table.insert(results, 'RGB Components:')
  table.insert(
    results,
    string.format('  Red:   %3d (0x%02x) %.1f%%', rgb[1], rgb[1], rgb[1] / 255 * 100)
  )
  table.insert(
    results,
    string.format('  Green: %3d (0x%02x) %.1f%%', rgb[2], rgb[2], rgb[2] / 255 * 100)
  )
  table.insert(
    results,
    string.format('  Blue:  %3d (0x%02x) %.1f%%', rgb[3], rgb[3], rgb[3] / 255 * 100)
  )

  if is_gray then
    table.insert(results, '  Note: Equal RGB values = neutral gray')
  end

  return results
end

-- ============================================================================
-- Theme Analysis
-- ============================================================================
local function analyze_theme_simple()
  local results = {}

  table.insert(results, '=== Scientific Theme Analysis ===')
  table.insert(results, 'Principles: LAB Uniformity + Comfortable Contrast + Moderate Saturation')
  table.insert(results, '')

  local color_list = {
    { 'cyan', 'String' },
    { 'green', 'Keyword' },
    { 'blue', 'Function' },
    { 'yellow', 'Type' },
    { 'violet', 'Constant' },
    { 'orange', 'Special' },
    { 'red', 'Error' },
    { 'magenta', 'Todo' },
  }

  -- Calculate L* uniformity
  local L_values = {}
  for _, item in ipairs(color_list) do
    local lch = rgb_to_lch(colors[item[1]])
    table.insert(L_values, lch.L)
  end

  local sum_L = 0
  for _, L in ipairs(L_values) do
    sum_L = sum_L + L
  end
  local mean_L = sum_L / #L_values

  local variance = 0
  for _, L in ipairs(L_values) do
    variance = variance + (L - mean_L) ^ 2
  end
  local std_dev = math.sqrt(variance / #L_values)

  table.insert(results, '【1. Lightness Uniformity】')
  table.insert(results, string.format('  Average L*: %.1f', mean_L))
  table.insert(results, string.format('  Std Dev:    %.1f', std_dev))
  if std_dev < 8 then
    table.insert(results, '  ✓ Excellent uniformity (low eye strain)')
  elseif std_dev < 12 then
    table.insert(results, '  ~ Good uniformity')
  else
    table.insert(results, '  ⚠ High variance (may cause fatigue)')
  end
  table.insert(results, '')

  -- Individual color analysis
  table.insert(results, '【2. Individual Colors】')
  table.insert(results, 'Color    L*    C*    H°    Contrast  Assessment')
  table.insert(
    results,
    '────────────────────────────────────────────────────'
  )

  local needs_adjustment = {}

  for _, item in ipairs(color_list) do
    local name, label = item[1], item[2]
    local hex = colors[name]
    local lch = rgb_to_lch(hex)
    local contrast = contrast_ratio(hex, colors.base03)

    local issues = {}
    if lch.L < 50 then
      table.insert(issues, 'dark')
    elseif lch.L > 70 then
      table.insert(issues, 'bright')
    end
    if lch.C < 35 then
      table.insert(issues, 'low sat')
    elseif lch.C > 75 then
      table.insert(issues, 'high sat')
    end
    if contrast < 4 then
      table.insert(issues, 'low contrast')
    elseif contrast > 7 then
      table.insert(issues, 'high contrast')
    end

    local status = #issues == 0 and '✓' or table.concat(issues, ',')

    table.insert(
      results,
      string.format(
        '%-8s %5.1f %5.1f %5.0f° %5.2f:1  %s',
        label,
        lch.L,
        lch.C,
        lch.H,
        contrast,
        status
      )
    )

    if #issues > 0 then
      table.insert(needs_adjustment, {
        name = name,
        label = label,
        lch = lch,
        issues = issues,
      })
    end
  end

  table.insert(
    results,
    '────────────────────────────────────────────────────'
  )
  table.insert(results, '')

  -- Optimization suggestions
  if #needs_adjustment == 0 then
    table.insert(results, '【3. Result】')
    table.insert(results, '  ✓ Your palette is well-balanced!')
  else
    table.insert(results, '【3. Suggested Micro-adjustments】')
    table.insert(results, '')

    for _, item in ipairs(needs_adjustment) do
      local current_hex = colors[item.name]
      local current_lch = item.lch

      local target_L = math.max(55, math.min(65, current_lch.L))
      if current_lch.L < 55 then
        target_L = 58
      elseif current_lch.L > 65 then
        target_L = 62
      end

      local target_C = math.max(40, math.min(70, current_lch.C))
      if current_lch.C < 40 then
        target_C = 50
      elseif current_lch.C > 70 then
        target_C = 60
      end

      local new_lch = {
        L = current_lch.L + (target_L - current_lch.L) * 0.3,
        C = current_lch.C + (target_C - current_lch.C) * 0.3,
        H = current_lch.H,
      }

      local new_hex = lch_to_rgb(new_lch)
      local new_contrast = contrast_ratio(new_hex, colors.base03)

      table.insert(results, string.format('%s (%s):', item.label, item.name))
      table.insert(results, string.format('  %s → %s', current_hex, new_hex))
      table.insert(
        results,
        string.format(
          '  L: %.1f→%.1f  C: %.1f→%.1f  Contrast: %.2f→%.2f',
          current_lch.L,
          new_lch.L,
          current_lch.C,
          new_lch.C,
          contrast_ratio(current_hex, colors.base03),
          new_contrast
        )
      )
      table.insert(results, '')
    end
  end

  return results
end

local function calculate_standard_fg(background, target_contrast)
  target_contrast = target_contrast or 6.3

  local low, high = 50, 90
  local best_L = 70
  local best_diff = 999

  for _ = 1, 50 do
    local mid = (low + high) / 2
    local test_val = math.floor((mid / 100) * 255 + 0.5)
    local test_hex = string.format('#%02x%02x%02x', test_val, test_val, test_val)
    local test_contrast = contrast_ratio(test_hex, background)

    local diff = math.abs(test_contrast - target_contrast)
    if diff < best_diff then
      best_diff = diff
      best_L = mid
    end

    if test_contrast < target_contrast then
      low = mid
    else
      high = mid
    end

    if diff < 0.01 then
      break
    end
  end

  local optimal_val = math.floor((best_L / 100) * 255 + 0.5)
  local optimal_hex = string.format('#%02x%02x%02x', optimal_val, optimal_val, optimal_val)

  return {
    hex = optimal_hex,
    L = best_L,
    contrast = contrast_ratio(optimal_hex, background),
  }
end

vim.api.nvim_create_user_command('ColorForeground', function(opts)
  print(vim.inspect(calculate_standard_fg(colors.base03, tonumber(opts.args))))
end, { desc = 'Analyze theme with scientific principles', nargs = '?' })

vim.api.nvim_create_user_command('ColorAnalyze', function()
  local results = analyze_theme_simple()
  vim.api.nvim_echo({ { table.concat(results, '\n'), 'Normal' } }, true, {})
end, { desc = 'Analyze theme with scientific principles' })

vim.api.nvim_create_user_command('ColorTest', function(opts)
  local results = test_color_detailed(opts.args)
  vim.api.nvim_echo({ { table.concat(results, '\n'), 'Normal' } }, true, {})
end, { nargs = 1, desc = 'Test a color with detailed analysis' })

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
h('@type.builtin', { link = 'Type' })
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
h('@keyword.import', { link = 'PreProc' })
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
h('DiagnosticVirtualTextError', { bg = blend(colors.red, colors.base03, 0.3) })
h('DiagnosticVirtualTextWarn', { bg = blend(colors.yellow, colors.base03, 0.5) })
h('DiagnosticVirtualTextInfo', { bg = blend(colors.blue, colors.base03, 0.5) })
h('DiagnosticVirtualTextHint', { bg = blend(colors.cyan, colors.base03, 0.5) })

h('DiagnosticPrefixError', { fg = colors.red, bg = blend(colors.red, colors.base03, 0.3) })
h('DiagnosticPrefixWarn', { fg = colors.yellow, bg = blend(colors.yellow, colors.base03, 0.5) })
h('DiagnosticPrefixInfo', { fg = colors.blue, bg = blend(colors.blue, colors.base03, 0.5) })
h('DiagnosticPrefixHint', { fg = colors.cyan, bg = blend(colors.cyan, colors.base03, 0.5) })

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
