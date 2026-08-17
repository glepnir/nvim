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

local function setup_highlights()
  local comment = api.nvim_get_hl(0, { name = 'Comment', link = false })
  comment.strikethrough = true

  local highlights = {
    AgendaTodo = { link = 'Function' },
    AgendaWip = { link = 'WarningMsg' },
    AgendaInbox = { link = 'Normal' },
    AgendaScheduled = { link = 'PreProc' },
    AgendaDeadline = { link = 'ErrorMsg' },
    AgendaHeader = { link = 'Keyword' },
    AgendaWeekHeader = { link = 'Comment' },
    AgendaToday = { link = 'Keyword' },
    AgendaWeekend = { link = 'PreProc' },
    AgendaTodoLabel = { link = 'Comment' },
    AgendaScheduledLabel = { link = 'Function' },
    AgendaDeadlineLabel = { link = 'ErrorMsg' },
    AgendaTime = { link = 'WarningMsg' },
    AgendaTimeDeadline = { link = 'ErrorMsg' },
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

-- Returns the ISO week number for a given timestamp
local function get_week_number(ts)
  ts = ts or os.time()
  local t = os.date('*t', ts)
  local jan1 = os.time({ year = t.year, month = 1, day = 1, hour = 12 })
  local yday = math.floor((ts - jan1) / 86400) + 1
  local iso_wday = (t.wday + 5) % 7 + 1
  local week = math.floor((yday - iso_wday + 10) / 7)
  if week < 1 then
    week = 52
  elseif week > 52 then
    local dec28 = os.time({ year = t.year, month = 12, day = 28, hour = 12 })
    local dec28_iso = (os.date('*t', dec28).wday + 5) % 7 + 1
    local dec28_yday = math.floor((dec28 - jan1) / 86400) + 1
    if math.floor((dec28_yday - dec28_iso + 10) / 7) >= week then
      week = 1
    end
  end
  return week
end

-- Returns a list of 7 timestamps (Mon..Sun) for the current week
local function get_week_days()
  local now = os.date('*t')
  local today_ts = os.time({ year = now.year, month = now.month, day = now.day, hour = 12 })
  -- wday: 1=Sun,2=Mon..7=Sat; offset to Monday
  local offset = (now.wday + 5) % 7
  local monday_ts = today_ts - offset * 86400
  local days = {}
  for i = 0, 6 do
    days[i + 1] = monday_ts + i * 86400
  end
  return days
end

-- Groups tasks by date string; each task appears under its scheduled and/or deadline date
local function group_tasks_by_day(tasks)
  local by_day = {}
  for _, task in ipairs(tasks) do
    if task.scheduled and task.scheduled ~= '' then
      by_day[task.scheduled] = by_day[task.scheduled] or {}
      table.insert(by_day[task.scheduled], { task = task, kind = 'scheduled' })
    end
    if task.deadline and task.deadline ~= '' then
      by_day[task.deadline] = by_day[task.deadline] or {}
      table.insert(by_day[task.deadline], { task = task, kind = 'deadline' })
    end
  end
  for _, entries in pairs(by_day) do
    table.sort(entries, function(a, b)
      if a.kind ~= b.kind then
        return a.kind == 'scheduled'
      end
      return (a.task.time or '') < (b.task.time or '')
    end)
  end
  return by_day
end

-- Builds rows for the week view.
-- Each row has: { kind, text, task_id?, highlights? }
-- kinds: 'header', 'day', 'today', 'weekend', 'task', 'empty'
local function build_week_view(tasks)
  local months = { 'January', 'February', 'March', 'April', 'May', 'June',
                   'July', 'August', 'September', 'October', 'November', 'December' }
  local weekday_names = { 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday' }

  local week_days = get_week_days()
  local week_num = get_week_number(week_days[1])
  local today_str = os.date('%Y-%m-%d')
  local by_day = group_tasks_by_day(tasks)

  local rows = {}

  -- Header
  table.insert(rows, {
    kind = 'header',
    text = string.format('Week-agenda (W%d):', week_num),
  })

  for i, day_ts in ipairs(week_days) do
    local dt = os.date('*t', day_ts)
    local day_str = string.format('%04d-%02d-%02d', dt.year, dt.month, dt.day)
    local wname = weekday_names[i]
    local is_today = (day_str == today_str)
    local is_weekend = (i >= 6) -- Saturday=6, Sunday=7

    -- Day header line: `Monday      9 July 2018 W28` (week number on first day)
    local day_text
    if i == 1 then
      day_text = string.format('%-11s %2d %s %d  W%d', wname, dt.day, months[dt.month], dt.year, week_num)
    else
      day_text = string.format('%-11s %2d %s %d', wname, dt.day, months[dt.month], dt.year)
    end

    local day_kind
    if is_today then
      day_kind = 'today'
    elseif is_weekend then
      day_kind = 'weekend'
    else
      day_kind = 'day'
    end

    table.insert(rows, { kind = day_kind, text = day_text })

    -- Task entries for this day
    local entries = by_day[day_str] or {}
    for _, entry in ipairs(entries) do
      local task = entry.task
      local is_deadline = (entry.kind == 'deadline')
      local time_str = (task.time and task.time ~= '') and task.time or '......'
      -- pad time to 5 chars then append '......'
      local time_col = string.format('%-5s......', time_str)
      local label = is_deadline and 'Deadline:  ' or 'Scheduled: '
      local status_str = task.status
      local line = string.format('  todo:   %s %s%s  %s', time_col, label, status_str, task.title)

      -- Compute byte offsets for highlights
      local todo_start = 2      -- '  ' prefix, then 'todo:'
      local todo_end = todo_start + #'todo:'
      local time_start = todo_end + 3  -- '   ' gap
      local time_end = time_start + #time_col
      local label_start = time_end + 1
      local label_end = label_start + #label
      local status_start = label_end
      local status_end = status_start + #status_str
      local title_start = status_end + 2
      local title_end = title_start + #task.title

      local time_hl = is_deadline and 'AgendaTimeDeadline' or 'AgendaTime'
      local label_hl = is_deadline and 'AgendaDeadlineLabel' or 'AgendaScheduledLabel'
      local status_hl = is_deadline and 'AgendaDeadline' or 'AgendaScheduled'
      local title_hl = task.status == 'DONE' and 'AgendaDone' or 'Normal'

      table.insert(rows, {
        kind = 'task',
        text = line,
        task_id = task.id,
        highlights = {
          { hl_group = 'AgendaTodoLabel', col_start = todo_start, col_end = todo_end },
          { hl_group = time_hl,           col_start = time_start, col_end = time_end },
          { hl_group = label_hl,          col_start = label_start, col_end = label_end },
          { hl_group = status_hl,         col_start = status_start, col_end = status_end },
          { hl_group = title_hl,          col_start = title_start, col_end = title_end },
        },
      })
    end
  end

  -- Footer hint
  table.insert(rows, { kind = 'empty', text = '' })
  table.insert(rows, {
    kind = 'footer',
    text = '  [n]New  [d]Done  [e]Edit  [D]Del  [r]Reload  [q]Quit',
  })

  return rows
end

local function render_agenda(buf, tasks)
  local rows = build_week_view(tasks)
  local lines = {}
  local highlights = {}

  state.line_task_map[buf] = {}

  for index, row in ipairs(rows) do
    lines[index] = row.text

    if row.kind == 'task' then
      state.line_task_map[buf][index] = row.task_id
      for _, hl in ipairs(row.highlights or {}) do
        table.insert(highlights, {
          line = index - 1,
          col_start = hl.col_start,
          col_end = hl.col_end,
          hl_group = hl.hl_group,
        })
      end
    elseif row.kind == 'header' then
      table.insert(highlights, {
        line = index - 1,
        col_start = 0,
        col_end = #row.text,
        hl_group = 'AgendaHeader',
      })
    elseif row.kind == 'today' then
      table.insert(highlights, {
        line = index - 1,
        col_start = 0,
        col_end = #row.text,
        hl_group = 'AgendaToday',
      })
    elseif row.kind == 'weekend' then
      table.insert(highlights, {
        line = index - 1,
        col_start = 0,
        col_end = #row.text,
        hl_group = 'AgendaWeekend',
      })
    elseif row.kind == 'day' then
      table.insert(highlights, {
        line = index - 1,
        col_start = 0,
        col_end = #row.text,
        hl_group = 'AgendaWeekHeader',
      })
    elseif row.kind == 'footer' then
      table.insert(highlights, {
        line = index - 1,
        col_start = 0,
        col_end = #row.text,
        hl_group = 'AgendaWeekHeader',
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

local function notify_error(message)
  vim.schedule(function()
    vim.notify(message, vim.log.levels.ERROR)
  end)
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
