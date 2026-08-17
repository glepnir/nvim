local api = vim.api
local uv = vim.loop

local group = api.nvim_create_augroup('Agenda', { clear = true })
local ns_id = api.nvim_create_namespace('agenda')

math.randomseed(uv.hrtime() % 1000000000)

local M = {}

local state = {
  line_task_map = {},
  tasks = {},
  restore_opts = {},
}

local status_config = {
  DONE = { icon = '✔', hl = 'AgendaDone' },
  TODO = { icon = '●', hl = 'AgendaTodo' },
  WIP = { icon = '◐', hl = 'AgendaWip' },
  INBOX = { icon = '○', hl = 'AgendaInbox' },
  SCHEDULED = { icon = '◆', hl = 'AgendaScheduled' },
  DEADLINE = { icon = '⚑', hl = 'AgendaDeadline' },
}

local function setup_highlights()
  local comment = api.nvim_get_hl(0, { name = 'Comment', link = false })
  comment.strikethrough = true

  local highlights = {
    AgendaTodo = { link = 'Function' },
    AgendaWip = { link = 'WarningMsg' },
    AgendaInbox = { link = 'Normal' },
    AgendaScheduled = { link = 'PreProc' },
    AgendaDeadline = { link = 'ErrorMsg' },
    AgendaBorder = { link = 'Comment' },
    AgendaHeader = { link = 'Keyword' },
    AgendaSection = { link = 'DashboardDate' },
  }

  api.nvim_set_hl(0, 'AgendaDone', comment)
  for name, opts in pairs(highlights) do
    api.nvim_set_hl(0, name, opts)
  end
end

local function task_file()
  return vim.fn.stdpath('data') .. '/agenda_tasks.json'
end

local function null_to_nil(value)
  if value == vim.NIL then
    return nil
  end
  return value
end

local function normalize_tasks(tasks)
  local normalized = {}

  for _, task in ipairs(tasks or {}) do
    table.insert(normalized, {
      id = task.id,
      title = task.title or '',
      status = task.status or 'TODO',
      scheduled = null_to_nil(task.scheduled),
      deadline = null_to_nil(task.deadline),
      time = null_to_nil(task.time),
      created_at = task.created_at or '',
    })
  end

  return normalized
end

local function encode_tasks(tasks)
  local encoded = {}

  for _, task in ipairs(tasks or {}) do
    table.insert(encoded, {
      id = task.id,
      title = task.title,
      status = task.status,
      scheduled = task.scheduled or vim.NIL,
      deadline = task.deadline or vim.NIL,
      time = task.time or vim.NIL,
      created_at = task.created_at,
    })
  end

  return { tasks = encoded }
end

local function parse_date(value)
  if type(value) ~= 'string' then
    return nil
  end

  local year, month, day = value:match('^(%d%d%d%d)%-(%d%d)%-(%d%d)$')
  if not year then
    return nil
  end

  return os.time({
    year = tonumber(year),
    month = tonumber(month),
    day = tonumber(day),
    hour = 12,
  })
end

local function current_week_range()
  local now = os.date('*t')
  local today = os.time({
    year = now.year,
    month = now.month,
    day = now.day,
    hour = 12,
  })
  local offset = (now.wday + 5) % 7
  local start_day = today - (offset * 24 * 60 * 60)
  local end_day = start_day + (6 * 24 * 60 * 60)
  return start_day, end_day
end

local function is_in_current_week(value)
  local timestamp = parse_date(value)
  if not timestamp then
    return false
  end

  local start_day, end_day = current_week_range()
  return timestamp >= start_day and timestamp <= end_day
end

local function get_weekday(value)
  local timestamp = parse_date(value)
  if not timestamp then
    return ''
  end

  return os.date('%a', timestamp)
end

local function get_header_date()
  local datetime = os.date('*t')
  local weekdays = { 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday' }
  local months = { 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec' }
  return string.format('%s, %d %s %d', weekdays[datetime.wday], datetime.year, months[datetime.month], datetime.day)
end

local function notify_error(message)
  vim.schedule(function()
    vim.notify(message, vim.log.levels.ERROR)
  end)
end

local function pad_right(text, width)
  local padding = math.max(0, width - vim.fn.strdisplaywidth(text))
  return text .. string.rep(' ', padding)
end

local function center_text(text, width)
  local display_width = vim.fn.strdisplaywidth(text)
  local padding = math.max(0, width - display_width)
  local left = math.floor(padding / 2)
  local right = padding - left
  return string.rep(' ', left) .. text .. string.rep(' ', right)
end

local function task_sort_key(task)
  return task.deadline or task.scheduled or task.created_at or ''
end

local function sort_tasks(tasks)
  table.sort(tasks, function(a, b)
    local a_time = a.time or ''
    local b_time = b.time or ''
    local a_key = task_sort_key(a)
    local b_key = task_sort_key(b)
    if a_key == b_key then
      if a_time == b_time then
        return (a.created_at or '') < (b.created_at or '')
      end
      return a_time < b_time
    end
    return a_key < b_key
  end)
  return tasks
end

function M.load_tasks(callback)
  local done = vim.schedule_wrap(function(tasks)
    callback(tasks)
  end)

  uv.fs_open(task_file(), 'r', 438, function(open_err, fd)
    if open_err or not fd then
      done({})
      return
    end

    uv.fs_fstat(fd, function(stat_err, stat)
      if stat_err or not stat then
        uv.fs_close(fd)
        done({})
        return
      end

      uv.fs_read(fd, stat.size, 0, function(read_err, data)
        uv.fs_close(fd)
        if read_err or not data or data == '' then
          done({})
          return
        end

        local ok, decoded = pcall(vim.json.decode, data)
        if not ok or type(decoded) ~= 'table' or type(decoded.tasks) ~= 'table' then
          done({})
          return
        end

        done(normalize_tasks(decoded.tasks))
      end)
    end)
  end)
end

function M.save_tasks(tasks, callback)
  local path = task_file()
  vim.fn.mkdir(vim.fn.fnamemodify(path, ':h'), 'p')

  local ok, payload = pcall(vim.json.encode, encode_tasks(tasks))
  if not ok then
    notify_error('Failed to encode agenda tasks')
    if callback then
      vim.schedule(callback)
    end
    return
  end

  uv.fs_open(path, 'w', tonumber('644', 8), function(open_err, fd)
    if open_err or not fd then
      notify_error('Failed to open agenda task file')
      if callback then
        vim.schedule(callback)
      end
      return
    end

    uv.fs_write(fd, payload, 0, function(write_err)
      uv.fs_close(fd)
      if write_err then
        notify_error('Failed to save agenda tasks')
      end
      if callback then
        vim.schedule(callback)
      end
    end)
  end)
end

function M.add_task(title, opts, callback)
  if not title or title == '' then
    if callback then
      callback()
    end
    return
  end

  opts = opts or {}
  M.load_tasks(function(tasks)
    table.insert(tasks, {
      id = 't' .. tostring(os.time()) .. tostring(math.random(1000, 9999)),
      title = title,
      status = opts.status or 'TODO',
      scheduled = opts.scheduled,
      deadline = opts.deadline,
      time = opts.time,
      created_at = os.date('%Y-%m-%dT%H:%M:%S'),
    })
    M.save_tasks(tasks, callback)
  end)
end

function M.toggle_done(id, tasks)
  for _, task in ipairs(tasks) do
    if task.id == id then
      task.status = task.status == 'DONE' and 'TODO' or 'DONE'
      break
    end
  end
  return tasks
end

function M.delete_task(id, tasks)
  for index, task in ipairs(tasks) do
    if task.id == id then
      table.remove(tasks, index)
      break
    end
  end
  return tasks
end

function M.update_title(id, title, tasks)
  for _, task in ipairs(tasks) do
    if task.id == id then
      task.title = title
      break
    end
  end
  return tasks
end

function M.get_today_tasks(tasks)
  local today = os.date('%Y-%m-%d')
  local today_tasks = {}

  for _, task in ipairs(tasks) do
    if
      (task.status == 'TODO' or task.status == 'WIP' or task.status == 'DONE' or task.status == 'INBOX')
      and (task.scheduled == today or task.scheduled == nil)
    then
      table.insert(today_tasks, task)
    end
  end

  return sort_tasks(today_tasks)
end

function M.get_week_tasks(tasks)
  local week_tasks = {}

  for _, task in ipairs(tasks) do
    if
      (task.deadline and is_in_current_week(task.deadline))
      or (task.status == 'SCHEDULED' and task.scheduled and is_in_current_week(task.scheduled))
    then
      table.insert(week_tasks, task)
    end
  end

  return sort_tasks(week_tasks)
end

local function build_task_line(task, is_week)
  local config = status_config[task.status] or status_config.INBOX
  local label = string.format('[%s]', task.status)
  local label_gap = string.rep(' ', math.max(1, 12 - vim.fn.strdisplaywidth(label)))
  local detail = ''

  if is_week then
    local weekday = get_weekday(task.deadline or task.scheduled)
    if weekday ~= '' then
      detail = weekday .. '  '
    end
  elseif task.time and task.time ~= '' then
    detail = task.time .. ' '
  end

  local line = string.format('  %s  %s%s%s%s', config.icon, label, label_gap, detail, task.title)
  local icon_start = 2
  local icon_end = icon_start + #config.icon
  local label_start = #('  ' .. config.icon .. '  ')
  local label_end = label_start + #label
  local detail_start = label_end + #label_gap
  local detail_end = detail_start + #detail
  local title_start = detail_end

  local title_group = task.status == 'DONE' and 'AgendaDone' or 'Normal'
  local highlights = {
    { hl_group = config.hl, col_start = icon_start, col_end = icon_end },
    { hl_group = config.hl, col_start = label_start, col_end = label_end },
  }

  if detail ~= '' then
    table.insert(highlights, {
      hl_group = 'AgendaInbox',
      col_start = detail_start,
      col_end = detail_end,
    })
  end

  table.insert(highlights, {
    hl_group = title_group,
    col_start = title_start,
    col_end = title_start + #task.title,
  })

  return {
    text = line,
    task_id = task.id,
    highlights = highlights,
  }
end

local function build_panel(tasks)
  local today_tasks = M.get_today_tasks(tasks)
  local week_tasks = M.get_week_tasks(tasks)
  local title = 'GTD Agenda  —  ' .. get_header_date()
  local footer = '  [n]New  [d]Done  [e]Edit  [D]Del  [r]Reload  [q]Quit'

  local rows = {
    { kind = 'title', text = title },
    { kind = 'section', text = '  TODAY' },
  }

  for _, task in ipairs(today_tasks) do
    table.insert(rows, vim.tbl_extend('force', { kind = 'task' }, build_task_line(task, false)))
  end

  table.insert(rows, { kind = 'section', text = '  THIS WEEK' })

  for _, task in ipairs(week_tasks) do
    table.insert(rows, vim.tbl_extend('force', { kind = 'task' }, build_task_line(task, true)))
  end

  table.insert(rows, { kind = 'footer', text = footer })

  local inner_width = 48
  for _, row in ipairs(rows) do
    inner_width = math.max(inner_width, vim.fn.strdisplaywidth(row.text))
  end

  local panel_lines = {
    { kind = 'border', text = '╔' .. string.rep('═', inner_width) .. '╗' },
    { kind = 'title', text = '║' .. center_text(title, inner_width) .. '║' },
    { kind = 'border', text = '╠' .. string.rep('═', inner_width) .. '╣' },
    { kind = 'section', text = '║' .. pad_right('  TODAY', inner_width) .. '║' },
  }

  for _, task in ipairs(today_tasks) do
    local row = build_task_line(task, false)
    table.insert(panel_lines, {
      kind = 'task',
      task_id = task.id,
      text = '║' .. pad_right(row.text, inner_width) .. '║',
      highlights = row.highlights,
    })
  end

  table.insert(panel_lines, { kind = 'border', text = '╠' .. string.rep('═', inner_width) .. '╣' })
  table.insert(panel_lines, { kind = 'section', text = '║' .. pad_right('  THIS WEEK', inner_width) .. '║' })

  for _, task in ipairs(week_tasks) do
    local row = build_task_line(task, true)
    table.insert(panel_lines, {
      kind = 'task',
      task_id = task.id,
      text = '║' .. pad_right(row.text, inner_width) .. '║',
      highlights = row.highlights,
    })
  end

  table.insert(panel_lines, { kind = 'border', text = '╠' .. string.rep('═', inner_width) .. '╣' })
  table.insert(panel_lines, { kind = 'footer', text = '║' .. pad_right(footer, inner_width) .. '║' })
  table.insert(panel_lines, { kind = 'border', text = '╚' .. string.rep('═', inner_width) .. '╝' })

  return panel_lines, inner_width
end

local function render_agenda(buf, tasks)
  local panel_lines, inner_width = build_panel(tasks)
  local total_width = inner_width + 2
  local left_margin = math.max(0, math.floor((vim.o.columns - total_width) / 2))
  local lines = {}
  local highlights = {}

  state.line_task_map[buf] = {}

  for index, row in ipairs(panel_lines) do
    local prefix = string.rep(' ', left_margin)
    local line = prefix .. row.text
    lines[index] = line

    if row.kind == 'task' then
      state.line_task_map[buf][index] = row.task_id
      for _, hl in ipairs(row.highlights or {}) do
        table.insert(highlights, {
          line = index - 1,
          col_start = left_margin + 1 + hl.col_start,
          col_end = left_margin + 1 + hl.col_end,
          hl_group = hl.hl_group,
        })
      end
    elseif row.kind == 'title' then
      table.insert(highlights, {
        line = index - 1,
        col_start = left_margin + 1,
        col_end = left_margin + #row.text - 1,
        hl_group = 'AgendaHeader',
      })
    elseif row.kind == 'section' then
      local content = row.text:match('║(.-)║$') or row.text
      local trimmed = content:find('%S') or 1
      local text = content:match('%S.*%S') or content:match('%S') or ''
      table.insert(highlights, {
        line = index - 1,
        col_start = left_margin + trimmed,
        col_end = left_margin + trimmed + #text,
        hl_group = 'AgendaSection',
      })
    elseif row.kind == 'border' then
      table.insert(highlights, {
        line = index - 1,
        col_start = left_margin,
        col_end = left_margin + #row.text,
        hl_group = 'AgendaBorder',
      })
    end
  end

  vim.bo[buf].modifiable = true
  api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].filetype = 'agenda'
  vim.bo[buf].modifiable = false
  api.nvim_buf_clear_namespace(buf, ns_id, 0, -1)

  for _, hl in ipairs(highlights) do
    vim.hl.range(buf, ns_id, hl.hl_group, { hl.line, hl.col_start }, { hl.line, hl.col_end })
  end
end

local function current_task_id(buf)
  local cursor = api.nvim_win_get_cursor(0)
  return state.line_task_map[buf] and state.line_task_map[buf][cursor[1]] or nil
end

local function reload(buf)
  M.load_tasks(function(tasks)
    if not api.nvim_buf_is_valid(buf) then
      return
    end
    state.tasks[buf] = tasks
    render_agenda(buf, tasks)
  end)
end

local function restore_opts(buf)
  local restore = state.restore_opts[buf]
  if not restore then
    return
  end

  vim.wo.number = restore.number
  vim.wo.relativenumber = restore.relativenumber
  vim.wo.cursorline = restore.cursorline
  vim.wo.signcolumn = restore.signcolumn
  vim.o.laststatus = restore.laststatus
  state.restore_opts[buf] = nil
end

local function setup_keymaps(buf)
  local opts = { buffer = buf }

  vim.keymap.set('n', 'n', function()
    vim.ui.input({ prompt = 'New task: ' }, function(title)
      M.add_task(title, nil, function()
        reload(buf)
      end)
    end)
  end, opts)

  local function save_and_reload(tasks)
    state.tasks[buf] = tasks
    M.save_tasks(tasks, function()
      reload(buf)
    end)
  end

  local function toggle_current()
    local id = current_task_id(buf)
    if not id then
      return
    end
    save_and_reload(M.toggle_done(id, state.tasks[buf] or {}))
  end

  vim.keymap.set('n', 'd', toggle_current, opts)
  vim.keymap.set('n', '<CR>', toggle_current, opts)

  vim.keymap.set('n', 'e', function()
    local id = current_task_id(buf)
    if not id then
      return
    end

    for _, task in ipairs(state.tasks[buf] or {}) do
      if task.id == id then
        vim.ui.input({ prompt = 'Edit task: ', default = task.title }, function(title)
          if not title or title == '' then
            return
          end
          save_and_reload(M.update_title(id, title, state.tasks[buf] or {}))
        end)
        break
      end
    end
  end, opts)

  vim.keymap.set('n', 'D', function()
    local id = current_task_id(buf)
    if not id then
      return
    end
    save_and_reload(M.delete_task(id, state.tasks[buf] or {}))
  end, opts)

  vim.keymap.set('n', 'r', function()
    reload(buf)
  end, opts)

  vim.keymap.set('n', 'q', '<cmd>bdelete<CR>', opts)
  vim.keymap.set('n', '<Esc>', '<cmd>bdelete<CR>', opts)
end

function M.show()
  if vim.fn.argc() > 0 or vim.fn.line2byte('$') ~= -1 then
    return
  end

  local buf = api.nvim_create_buf(false, true)
  api.nvim_set_current_buf(buf)

  setup_highlights()
  setup_keymaps(buf)

  state.restore_opts[buf] = {
    number = vim.wo.number,
    relativenumber = vim.wo.relativenumber,
    cursorline = vim.wo.cursorline,
    signcolumn = vim.wo.signcolumn,
    laststatus = vim.o.laststatus,
  }

  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].buflisted = false
  vim.bo[buf].modifiable = false
  vim.wo.number = false
  vim.wo.relativenumber = false
  vim.wo.cursorline = true
  vim.wo.signcolumn = 'no'
  vim.o.laststatus = 0

  reload(buf)

  api.nvim_create_autocmd('VimResized', {
    buffer = buf,
    group = group,
    callback = function()
      reload(buf)
    end,
  })

  api.nvim_create_autocmd({ 'BufLeave', 'BufWipeout' }, {
    buffer = buf,
    group = group,
    callback = function()
      restore_opts(buf)
    end,
  })
end

api.nvim_create_autocmd('ColorScheme', {
  group = group,
  callback = function()
    setup_highlights()
  end,
})

api.nvim_create_user_command('Agenda', function()
  M.show()
end, {})

return M
