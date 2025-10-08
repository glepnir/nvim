local group = vim.api.nvim_create_augroup('Dashboard', { clear = true })

local M = {}

local config = {
  lambda_art = {
    '⠀⠀⠀⢀⣠⣴⣶⣤⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀',
    '⠀⠀⣴⣿⣿⣿⣿⣿⣿⣿⣆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀',
    '⠀⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀',
    '⠘⣿⣿⣿⣿⡟⠉⢿⣿⣿⣿⣿⣆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀',
    '⠀⠈⠛⠛⠋⠀⠀⠈⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀',
    '⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣿⣿⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀',
    '⠀⠀⠀⠀⠀⠀⠀⠀⣸⣿⣿⣿⣿⣿⣧⠀⠀⠀⠀⠀⠀⠀⠀⠀',
    '⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀',
    '⠀⠀⠀⠀⠀⠀⣰⣿⣿⣿⣿⣿⣿⣿⣿⣷⠀⠀⠀⠀⠀⠀⠀⠀',
    '⠀⠀⠀⠀⢀⣼⣿⣿⣿⣿⡿⢿⣿⣿⣿⣿⡆⠀⠀⠀⠀⠀⠀⠀',
    '⠀⠀⠀⢠⣾⣿⣿⣿⣿⡟⠁⠘⣿⣿⣿⣿⣷⠀⠀⠀⣀⡀⠀⠀',
    '⠀⠀⣠⣿⣿⣿⣿⣿⠏⠀⠀⠀⢻⣿⣿⣿⣿⡆⣰⣿⣿⣿⣷⡀',
    '⠀⣴⣿⣿⣿⣿⣿⠋⠀⠀⠀⠀⠘⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠁',
    '⠰⣿⣿⣿⣿⡿⠁⠀⠀⠀⠀⠀⠀⠘⢿⣿⣿⣿⣿⣿⣿⡟⠁⠀',
    '⠀⠙⠻⠿⠛⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠛⠿⠟⠛⠁⠀⠀⠀',
  },

  shortcuts = {
    { key = 'f', desc = 'Open File', action = '<cmd>FzfLua files<CR>' },
    { key = 'o', desc = 'Recent Files', action = '<cmd>FzfLua oldfiles<CR>' },
    { key = 'd', desc = 'Dotfiles', action = '<cmd>FzfLua files cwd=$HOME/.config<CR>' },
    { key = 'e', desc = 'New File', action = '<cmd>enew<CR>' },
    { key = 'u', desc = 'Update Plugins', action = '<cmd>Strive update<CR>' },
    { key = 'q', desc = 'Quit', action = '<cmd>qa<CR>' },
  },

  highlights = {
    lambda = 'DashboardLambda',
    key = 'DashboardKey',
    desc = 'DashboardDesc',
    date = 'DashboardDate',
    footer = 'DashboardFooter',
  },

  layout = {
    top_offset = 8,
    date_top_offset = 3,
    plugin_info_offset = 5,
    shortcuts_top_offset = 3,
  },
}

local function calculate_positions()
  local screen_width = vim.o.columns

  local lambda_display_width = 0
  for _, line in ipairs(config.lambda_art) do
    lambda_display_width = math.max(lambda_display_width, vim.fn.strdisplaywidth(line))
  end

  local max_right_display_width = 0

  local sample_plugin = 'load 999/999 plugins in 9999.999ms'
  max_right_display_width = math.max(max_right_display_width, vim.fn.strdisplaywidth(sample_plugin))

  local gap = 2

  local total_display_width = lambda_display_width + gap + max_right_display_width

  local start_pos = math.max(1, math.floor((screen_width - total_display_width) / 2))

  return {
    lambda_left_margin = start_pos,
    right_section_left = start_pos + lambda_display_width + gap,
  }
end

local function setup_highlights()
  local highlights = {
    DashboardLambda = { fg = '#7aa2f7', bold = true },
    DashboardKey = { fg = '#f7768e', bold = true },
    DashboardDesc = { fg = '#9ece6a' },
    DashboardDate = { fg = '#e0af68', bold = true },
    DashboardFooter = { fg = '#565f89', italic = true },
  }

  for g, opts in pairs(highlights) do
    vim.api.nvim_set_hl(0, g, opts)
  end
end

local function get_datetime()
  local datetime = os.date('*t')
  local weekdays = { 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday' }
  local months =
    { 'jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec' }

  local weekday = weekdays[datetime.wday]
  local year = datetime.year
  local month = months[datetime.month]
  local day = datetime.day
  local hour = string.format('%02d', datetime.hour)
  local min = string.format('%02d', datetime.min)

  return string.format('%s %d %s %d %s:%s', weekday, year, month, day, hour, min)
end

local function create_dashboard_buffer()
  local buf = vim.api.nvim_get_current_buf()
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].buflisted = false
  vim.bo[buf].modifiable = false
  return buf
end

local function render_dashboard(buf)
  local lines = {}
  local highlights_to_apply = {}

  local pos = calculate_positions()

  for _ = 1, config.layout.top_offset do
    table.insert(lines, '')
  end

  local lambda_lines = #config.lambda_art
  local date_line_idx = config.layout.top_offset + config.layout.date_top_offset
  local plugin_info_line_idx = config.layout.top_offset + config.layout.plugin_info_offset
  local shortcuts_start_idx = plugin_info_line_idx + config.layout.shortcuts_top_offset

  local total_lines = math.max(
    config.layout.top_offset + lambda_lines,
    shortcuts_start_idx + #config.shortcuts,
    plugin_info_line_idx + 1
  )

  for _ = #lines + 1, total_lines do
    table.insert(lines, '')
  end

  for i, lambda_line in ipairs(config.lambda_art) do
    local line_idx = config.layout.top_offset + i
    if line_idx <= #lines then
      local new_line = string.rep(' ', pos.lambda_left_margin - 1) .. lambda_line
      lines[line_idx] = new_line

      local lambda_byte_start = pos.lambda_left_margin - 1
      local lambda_byte_end = lambda_byte_start + #lambda_line

      table.insert(highlights_to_apply, {
        line = line_idx - 1,
        col_start = lambda_byte_start,
        col_end = lambda_byte_end,
        hl_group = config.highlights.lambda,
      })
    end
  end

  local datetime_str = get_datetime()
  if date_line_idx <= #lines then
    local current_line = lines[date_line_idx] or ''
    local needed_spaces = math.max(0, pos.right_section_left - 1 - #current_line)
    local new_line = current_line .. string.rep(' ', needed_spaces) .. datetime_str
    lines[date_line_idx] = new_line

    local date_byte_start = #current_line + needed_spaces
    local date_byte_end = date_byte_start + #datetime_str

    table.insert(highlights_to_apply, {
      line = date_line_idx - 1,
      col_start = date_byte_start,
      col_end = date_byte_end,
      hl_group = config.highlights.date,
    })
  end

  local startup_time = vim.g.strive_startup_time or '0'
  local plugin_info_str = string.format(
    'load %d/%d plugins in %sms',
    vim.g.strive_loaded or 0,
    vim.g.strive_count or 0,
    startup_time
  )

  if plugin_info_line_idx <= #lines then
    local current_line = lines[plugin_info_line_idx] or ''
    local needed_spaces = math.max(0, pos.right_section_left - 1 - #current_line)
    local new_line = current_line .. string.rep(' ', needed_spaces) .. plugin_info_str
    lines[plugin_info_line_idx] = new_line

    local plugin_byte_start = #current_line + needed_spaces
    local plugin_byte_end = plugin_byte_start + #plugin_info_str

    table.insert(highlights_to_apply, {
      line = plugin_info_line_idx - 1,
      col_start = plugin_byte_start,
      col_end = plugin_byte_end,
      hl_group = config.highlights.footer,
    })
  end

  local cursor = {}

  local shortcuts = config.shortcuts
  for i, shortcut in ipairs(shortcuts) do
    local row_idx = shortcuts_start_idx + i - 1
    if row_idx <= #lines then
      local shortcut_text = string.format('[%s]  %s', shortcut.key, shortcut.desc)

      local current_line = lines[row_idx] or ''
      local needed_spaces = math.max(2, pos.right_section_left - 1 - #current_line)
      local new_line = current_line .. string.rep(' ', needed_spaces) .. shortcut_text
      if i == 1 then
        cursor[1] = row_idx
        cursor[2] = #new_line - #shortcut_text + 5
      end
      lines[row_idx] = new_line

      local shortcut_byte_start = #current_line + needed_spaces

      table.insert(highlights_to_apply, {
        line = row_idx - 1,
        col_start = shortcut_byte_start + 1,
        col_end = shortcut_byte_start + 2,
        hl_group = config.highlights.key,
      })

      table.insert(highlights_to_apply, {
        line = row_idx - 1,
        col_start = shortcut_byte_start + 3,
        col_end = shortcut_byte_start + #shortcut_text,
        hl_group = config.highlights.desc,
      })
    end
  end

  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.api.nvim_win_set_cursor(0, cursor)

  local ns_id = vim.api.nvim_create_namespace('dashboard')
  for _, hl in ipairs(highlights_to_apply) do
    vim.hl.range(buf, ns_id, hl.hl_group, { hl.line, hl.col_start }, { hl.line, hl.col_end })
  end
end

local function setup_keymaps(buf)
  local opts = { noremap = true, silent = true, buffer = buf }

  for _, shortcut in ipairs(config.shortcuts) do
    vim.keymap.set('n', shortcut.key, shortcut.action, opts)
  end

  vim.keymap.set('n', '<Esc>', ':q<CR>', opts)
  vim.keymap.set('n', 'q', ':q<CR>', opts)
end

local function opt_handler()
  local save_opts = {}

  save_opts.number = vim.wo.number
  save_opts.relativenumber = vim.wo.relativenumber
  save_opts.cursorline = vim.wo.cursorline
  save_opts.cursorcolumn = vim.wo.cursorcolumn
  save_opts.colorcolumn = vim.wo.colorcolumn
  save_opts.signcolumn = vim.wo.signcolumn
  save_opts.wrap = vim.wo.wrap
  save_opts.laststatus = vim.o.laststatus
  save_opts.showtabline = vim.o.showtabline
  save_opts.listchars = vim.o.listchars

  return function()
    vim.wo.number = save_opts.number
    vim.wo.relativenumber = save_opts.relativenumber
    vim.wo.cursorline = save_opts.cursorline
    vim.wo.cursorcolumn = save_opts.cursorcolumn
    vim.wo.colorcolumn = save_opts.colorcolumn
    vim.wo.signcolumn = save_opts.signcolumn
    vim.wo.wrap = save_opts.wrap
    vim.o.laststatus = save_opts.laststatus
    vim.o.showtabline = save_opts.showtabline
    vim.o.listchars = save_opts.listchars
  end
end

function M.show()
  if vim.fn.argc() > 0 or vim.fn.line2byte('$') ~= -1 then
    return
  end

  local buf = create_dashboard_buffer()
  vim.api.nvim_set_current_buf(buf)
  render_dashboard(buf)
  setup_highlights()
  setup_keymaps(buf)

  local restore_opt = opt_handler()

  vim.wo.number = false
  vim.wo.relativenumber = false
  vim.wo.cursorline = false
  vim.wo.cursorcolumn = false
  vim.wo.colorcolumn = '0'
  vim.wo.signcolumn = 'no'
  vim.wo.wrap = false
  vim.wo.listchars = 'precedes: '

  vim.o.laststatus = 0
  vim.o.showtabline = 0

  vim.api.nvim_create_autocmd('VimResized', {
    buffer = buf,
    group = group,
    callback = function()
      if vim.bo.buftype == 'nofile' and vim.bo.filetype == '' then
        render_dashboard(buf)
      end
    end,
  })

  vim.api.nvim_create_autocmd('BufLeave', {
    buffer = buf,
    group = group,
    callback = function()
      restore_opt()
    end,
  })
end

vim.api.nvim_create_autocmd('VimEnter', {
  group = group,
  callback = function()
    if vim.fn.argc() == 0 and vim.fn.line2byte('$') == -1 then
      M.show()
    end
  end,
})

vim.api.nvim_create_user_command('Dashboard', function()
  M.show()
end, {})

return M
