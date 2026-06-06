local api = vim.api
local last_cmd = nil
local qf_id = nil
local ansi_ns = nil
local chan_id = nil ---@type integer?

--- Strip ANSI escape sequences from a string.
local function strip_ansi(s)
  return (s:gsub('\27%[[%d;]*m', ''))
end

--- Strip carriage-returns injected by the PTY line-discipline.
local function strip_cr(s)
  return (s:gsub('\r', ''))
end

local function strip_bs(s)
  local prev
  repeat
    prev = s
    s = s:gsub('.\8', '')
  until s == prev
  return s
end

local function clean(s)
  s = strip_cr(s)
  s = strip_bs(s)
  s = strip_ansi(s)
  s = s:gsub('[%z\1-\8\11-\31\127]', '')
  return s
end

--- Match a compiler diagnostic header line: `file:line:col: type: msg`.
--- Tries a Windows drive-letter path first (e.g. C:\src\main.cpp:5:1),
--- then falls back to the generic (Unix) form. Returns all-or-nothing.
local function match_diag(line)
  local f, l, c, t, m = line:match('^(%a:[/\\][^:]+):(%d+):(%d+):%s*(%w+):%s*(.*)$')
  if not f then
    f, l, c, t, m = line:match('^([^:]+):(%d+):(%d+):%s*(%w+):%s*(.*)$')
  end
  return f, l, c, t, m
end

local function parse_err(text, save_item)
  local list = {}
  local lines = vim.split(text, '\n', { trimempty = true })

  local i = 1
  local prev_item = {}
  while i <= #lines do
    local raw = lines[i]
    local line = clean(raw)

    local filename, lnum, col, type_str, msg = match_diag(line)

    if filename and lnum and col then
      local bufnr = vim.fn.bufadd(filename)
      prev_item = {
        filename = filename,
        lnum = tonumber(lnum),
        col = tonumber(col),
        type = type_str:sub(1, 1):upper(),
        text = type_str:lower() .. ': ' .. msg,
        bufnr = bufnr,
        _raw = raw,
      }
      table.insert(list, prev_item)
      if save_item then
        save_item.lnum = prev_item.lnum
        save_item.col = prev_item.col
        save_item.bufnr = prev_item.bufnr
        save_item.filename = prev_item.filename
      end

      local j = i + 1
      while j <= #lines do
        local next_raw = lines[j]
        local next_line = clean(next_raw)
        if
          next_line:match('^%s*%d+%s*|')
          or next_line:match('^%s*|')
          or next_line:match('^%s*%^')
          or next_line:match('generated')
        then
          table.insert(list, {
            filename = prev_item.filename,
            bufnr = prev_item.bufnr,
            text = next_raw,
            lnum = prev_item.lnum,
            col = prev_item.col,
            user_data = 'compile_info',
          })
          j = j + 1
        else
          break
        end
      end
      i = j
    else
      if save_item and save_item.bufnr then
        table.insert(list, {
          filename = save_item.filename,
          bufnr = save_item.bufnr,
          lnum = save_item.lnum,
          col = save_item.col,
          text = raw,
          user_data = 'compile_info',
        })
      else
        table.insert(list, { text = raw, user_data = 'compile_info' })
      end
      i = i + 1
    end
  end

  return list
end

local function apply_qf_syntax()
  vim.cmd([[
    syntax clear
    syntax match QfFileName /^[^ ]*\ze:\d\+:\d\+/
    syntax match QfLineCol  /^[^ ]*:\zs\d\+:\d\+/
    syntax match QfError    /error:/
    syntax match QfWarning  /warning:/
    syntax match QfNote     /note:/
    syntax match QfFinish   /\<finished\>/
    syntax match QfExit     /\<exited abnormally\>/
    syntax match QfCode     /\vcode\s+\zs\d+/
    syntax match QfDuration /duration\s\+\zs[0-9.]\+s/
    syntax match QfTime     /\d\d:\d\d:\d\d/
    syntax match QfCaret    /\s\+\^\~*/
    syntax match QfTilde    /\~\+/

    highlight QfFileName guifg=#992c3d ctermfg=Red    gui=bold,underline
    highlight QfLineCol  guifg=#c7c938 ctermfg=Yellow
    highlight QfError    guifg=#e06c75 ctermfg=Red    gui=bold
    highlight QfWarning  guifg=#e5c07b ctermfg=Yellow gui=bold
    highlight QfNote     guifg=#56b6c2 ctermfg=Cyan   gui=bold
    highlight QfFinish   guifg=#62c92a ctermfg=Green
    highlight QfExit     guifg=#992c3d ctermfg=Red    gui=bold
    highlight QfCode     guifg=#992c3d ctermfg=Red    gui=bold
    highlight QfDuration guifg=#c7c938 ctermfg=Yellow
    highlight QfTime     guifg=#c7c938 ctermfg=Yellow
    highlight QfCaret    guifg=#e5c07b ctermfg=Yellow gui=bold
    highlight QfTilde    guifg=#c7c938 ctermfg=Yellow
  ]])
end

local ansi_colors = {
  ['30'] = 'Black',
  ['31'] = 'Red',
  ['32'] = 'Green',
  ['33'] = 'Yellow',
  ['34'] = 'Blue',
  ['35'] = 'Magenta',
  ['36'] = 'Cyan',
  ['37'] = 'White',
}

local function make_qf_textfunc()
  local lpeg = vim.lpeg
  local P, R, C, Ct = lpeg.P, lpeg.R, lpeg.C, lpeg.Ct

  local esc = P('\27')
  local num = R('09') ^ 1
  local code = esc
    * '['
    * C((num * (P(';') * num) ^ 0))
    * 'm'
    / function(params)
      local color = nil
      for n in params:gmatch('%d+') do
        local v = tonumber(n)
        if v >= 30 and v <= 37 then
          color = tostring(v)
        end
      end
      return { type = 'code', value = color or '0' }
    end

  local text_seg = C((1 - esc) ^ 1) / function(t)
    return { type = 'text', value = t }
  end

  local grammar = Ct((code + text_seg) ^ 0)

  return function(info)
    local lines = {}
    local line_colors = {}

    local res = vim.fn.getqflist({ id = info.id, items = 1, winid = 0 })
    local items = res.items

    for i = info.start_idx, info.end_idx do
      local item = items[i]

      if item.user_data == 'compile_info' then
        local segs = grammar:match(strip_bs(item.text or ''))
        local plain = {}
        local active = nil

        for _, seg in ipairs(segs) do
          if seg.type == 'code' then
            local c = seg.value
            if c ~= '0' and ansi_colors[c] then
              if active then
                active._end = #table.concat(plain)
              end
              active = {
                lnum = i,
                start = #table.concat(plain),
                color = ansi_colors[c],
                code = tonumber(c),
              }
              table.insert(line_colors, active)
            else
              if active then
                active._end = #table.concat(plain)
                active = nil
              end
            end
          else
            table.insert(plain, seg.value)
          end
        end

        if active then
          active._end = #table.concat(plain)
        end
        table.insert(lines, table.concat(plain))
      elseif item.bufnr ~= 0 then
        local fname = vim.fn.bufname(item.bufnr)
        local lnum_s = tostring(item.lnum)
        local col_s = tostring(item.col)
        local line_text = string.format('%s:%s:%s %s', fname, lnum_s, col_s, item.text)
        table.insert(lines, line_text)

        table.insert(line_colors, {
          lnum = i,
          start = 0,
          _end = #fname,
          color = nil,
          hl = 'QfFileName',
        })
        table.insert(line_colors, {
          lnum = i,
          start = #fname + 1,
          _end = #fname + 1 + #lnum_s + 1 + #col_s,
          hl = 'QfLineCol',
        })
      else
        table.insert(lines, item.text or '')
      end
    end

    if #line_colors > 0 and res.winid ~= 0 then
      local buf = api.nvim_win_get_buf(res.winid)
      vim.schedule(function()
        for _, c in ipairs(line_colors) do
          local hl_group = c.hl or ('ANSI' .. c.color)
          if c.color then
            api.nvim_set_hl(ansi_ns, hl_group, { ctermfg = c.code, fg = c.color })
          end
          api.nvim_buf_set_extmark(buf, ansi_ns, c.lnum - 1, c.start, {
            end_col = c._end,
            hl_group = hl_group,
          })
        end
      end)
    end

    return lines
  end
end

local function open_qf_now(cmd_text)
  local start_text = ('Compilation started at %s'):format(os.date('%a %b %H:%M:%S'))
  qf_id = nil

  vim.fn.setqflist({}, ' ', {
    title = 'Compiling',
    items = {
      { user_data = 'compile_info', text = start_text },
      { user_data = 'compile_info', text = ' ' },
      { user_data = 'compile_info', text = cmd_text },
    },
    quickfixtextfunc = make_qf_textfunc(),
  })

  qf_id = vim.fn.getqflist({ nr = '$', id = 0 }).id

  local curwin
  local qf_win = vim.fn.getqflist({ winid = 0 }).winid
  if qf_win == 0 then
    curwin = api.nvim_get_current_win()
    vim.cmd.copen()
    qf_win = api.nvim_get_current_win()
    api.nvim_win_set_hl_ns(qf_win, ansi_ns)
    vim.opt_local.number = false
    vim.opt_local.signcolumn = 'no'
    vim.opt_local.list = false
    vim.opt_local.listchars = ''
    vim.bo.textwidth = 0
  end

  do
    local qf_buf = api.nvim_win_get_buf(qf_win)
    api.nvim_win_set_cursor(qf_win, { api.nvim_buf_line_count(qf_buf), 0 })
  end

  if curwin and api.nvim_win_is_valid(curwin) then
    api.nvim_set_current_win(curwin)
  end

  api.nvim_win_call(qf_win, function()
    apply_qf_syntax()
  end)
end

local function update_qf(qf_list, over)
  -- Snapshot "was tailing" BEFORE setqflist changes count.
  local qf_win = vim.fn.getqflist({ winid = 0 }).winid
  local was_tailing = false
  if qf_win ~= 0 and api.nvim_win_is_valid(qf_win) then
    local buf = api.nvim_win_get_buf(qf_win)
    local old_count = api.nvim_buf_line_count(buf)
    local cursor = api.nvim_win_get_cursor(qf_win)
    was_tailing = cursor[1] >= old_count
  end

  vim.fn.setqflist({}, 'a', {
    id = qf_id,
    items = qf_list,
    title = over and 'Compilation' or 'Compiling',
  })

  qf_win = vim.fn.getqflist({ winid = 0 }).winid
  if qf_win ~= 0 and api.nvim_win_is_valid(qf_win) then
    api.nvim_win_call(qf_win, function()
      if was_tailing or over then
        local count = api.nvim_buf_line_count(0)
        api.nvim_win_set_cursor(qf_win, { count, 0 })
        if over then
          local save = vim.wo[qf_win].scrolloff
          vim.wo[qf_win].scrolloff = 999
          vim.cmd('normal! zz')
          vim.wo[qf_win].scrolloff = save
        end
      end
      apply_qf_syntax()
    end)
  end
end

local function make_cmd(compile_cmd)
  if vim.fn.has('win32') == 1 then
    return compile_cmd
  end
  -- jobstart with pty=true handles PTY allocation, no need for script(1).
  return { 'sh', '-c', compile_cmd }
end

local function compiler(compile_cmd, bufname, opts)
  if compile_cmd:find('%%s') then
    local cwd = vim.uv.cwd()
    if bufname:find(cwd, 1, true) then
      bufname = bufname:sub(#cwd + 2)
    end
    -- Function replacement: a literal '%' in the path can't corrupt the
    -- gsub replacement string this way (a plain string repl would error).
    compile_cmd = compile_cmd:gsub('%%s', function()
      return bufname
    end)
  end
  last_cmd = compile_cmd
  if not opts.silent then
    open_qf_now(compile_cmd)
  end

  local start_time = vim.uv.hrtime()
  local out_buffer = ''
  local save_item = {}
  -- Captured by on_exit so a *previously killed* job can't clear the
  -- chan_id of the job we just started (the on_exit race).
  local job_id ---@type integer?

  job_id = vim.fn.jobstart(make_cmd(compile_cmd), {
    pty = true,
    on_stdout = function(_, data, _)
      -- jobstart with pty=true delivers data as a list of strings (split on \n).
      -- Join them back; empty trailing element means the last chunk ended with \n.
      if not data or (#data == 1 and data[1] == '') then
        return
      end
      local raw = table.concat(data, '\n')

      vim.schedule(function()
        out_buffer = out_buffer .. strip_cr(raw)
        local lines = vim.split(out_buffer, '\n', { plain = true })
        if not raw:match('\n$') and not (data[#data] == '') then
          out_buffer = lines[#lines]
          table.remove(lines, #lines)
        else
          out_buffer = ''
        end

        local plain_list = {}
        local err_text_lines = {}

        for _, line in ipairs(lines) do
          if line == '' then
            goto continue
          end
          local stripped = clean(line)
          if
            match_diag(stripped)
            or stripped:match('^%s*%d+%s*|')
            or stripped:match('^%s*|')
            or stripped:match('^%s*%^')
            or stripped:match('generated')
          then
            table.insert(err_text_lines, line)
          else
            if #err_text_lines > 0 then
              local err_list = parse_err(table.concat(err_text_lines, '\n'), save_item)
              if not opts.silent and #err_list > 0 then
                update_qf(err_list)
              end
              err_text_lines = {}
            end
            table.insert(plain_list, { text = line, user_data = 'compile_info' })
          end
          ::continue::
        end

        if #err_text_lines > 0 then
          local err_list = parse_err(table.concat(err_text_lines, '\n'), save_item)
          if not opts.silent and #err_list > 0 then
            update_qf(err_list)
          end
        end
        if not opts.silent and #plain_list > 0 then
          update_qf(plain_list)
        end
      end)
    end,

    on_exit = function(_, exit_code, _)
      local duration = (vim.uv.hrtime() - start_time) / 1e9
      vim.schedule(function()
        -- Only clear chan_id if we are still the active job. A job that was
        -- jobstop()'d earlier must not null out the freshly started one.
        if chan_id == job_id then
          chan_id = nil
        end
        if not opts.silent then
          local list = {}
          local flushed = clean(out_buffer)
          if flushed ~= '' then
            local tail = parse_err(strip_cr(flushed), save_item)
            if #tail > 0 then
              vim.list_extend(list, tail)
            else
              table.insert(list, { text = strip_cr(out_buffer), user_data = 'compile_info' })
            end
          end
          out_buffer = ''
          table.insert(list, { user_data = 'compile_info', text = ' ' })
          table.insert(list, {
            user_data = 'compile_info',
            text = ('Compilation %s at %s, duration %.3fs'):format(
              exit_code ~= 0 and 'exited abnormally with code ' .. exit_code or 'finished',
              os.date('%a %b %H:%M:%S'),
              duration
            ),
          })
          update_qf(list, true)
        end

        if opts.ondone then
          opts.ondone(exit_code)
        end
      end)
    end,
  })

  chan_id = job_id

  if not job_id or job_id <= 0 then
    vim.notify('Failed to start job: ' .. compile_cmd, vim.log.levels.ERROR)
    if chan_id == job_id then
      chan_id = nil
    end
  end
end

--- Find the project root by walking up from the current buffer.
--- Falls back to the current working directory.
local function find_root()
  local root = vim.fs.root(0, {
    '.git',
    '.svn',
    'Makefile',
    'CMakeLists.txt',
    'compile_commands.json',
    '.env',
  })
  return root or vim.uv.cwd()
end

local function read_compile_command()
  local env_file = vim.fs.joinpath(find_root(), '.env')

  local stat = vim.uv.fs_stat(env_file)
  if not stat or stat.size == 0 then
    return nil
  end

  local fd = vim.uv.fs_open(env_file, 'r', 438)
  if not fd then
    return nil
  end

  local data = vim.uv.fs_read(fd, stat.size, 0)
  vim.uv.fs_close(fd)
  if not data then
    return nil
  end

  for _, line in ipairs(vim.split(data, '\n')) do
    if vim.startswith(line, 'COMPILE_COMMAND') then
      return vim.trim(line:sub(17))
    end
  end
  return nil
end

--- Write (or update) COMPILE_COMMAND in the project-root .env file.
--- Preserves any other lines already present. Returns the path on success.
local function write_compile_command(cmd)
  cmd = vim.trim(cmd)
  local env_file = vim.fs.joinpath(find_root(), '.env')

  local lines = {}
  local replaced = false

  local stat = vim.uv.fs_stat(env_file)
  if stat and stat.size > 0 then
    local fd = vim.uv.fs_open(env_file, 'r', 438)
    if fd then
      local data = vim.uv.fs_read(fd, stat.size, 0) or ''
      vim.uv.fs_close(fd)
      for _, line in ipairs(vim.split(data, '\n')) do
        if vim.startswith(line, 'COMPILE_COMMAND') then
          table.insert(lines, 'COMPILE_COMMAND=' .. cmd)
          replaced = true
        else
          table.insert(lines, line)
        end
      end
    end
  end

  if not replaced then
    while #lines > 0 and lines[#lines] == '' do
      table.remove(lines)
    end
    table.insert(lines, 'COMPILE_COMMAND=' .. cmd)
  end

  local fd = vim.uv.fs_open(env_file, 'w', tonumber('644', 8))
  if not fd then
    vim.notify('Failed to write ' .. env_file, vim.log.levels.ERROR)
    return nil
  end
  vim.uv.fs_write(fd, table.concat(lines, '\n') .. '\n', 0)
  vim.uv.fs_close(fd)
  vim.notify('Saved COMPILE_COMMAND -> ' .. env_file, vim.log.levels.INFO)
  return env_file
end

--- Pull an inline `++silent` flag out of a command string.
--- `+` is a Lua pattern metachar, so use a plain find and an escaped gsub.
local function strip_silent(cmd)
  if cmd:find('++silent', 1, true) then
    return vim.trim((cmd:gsub('%+%+silent', ''))), true
  end
  return cmd, false
end

local function chan_alive()
  if not chan_id then
    return false
  end
  local ok, info = pcall(api.nvim_get_chan_info, chan_id)
  return ok and info and next(info) ~= nil
end

local function close_running()
  if chan_alive() then
    vim.fn.jobstop(chan_id)
    vim.notify('stopped compile job', vim.log.levels.WARN)
  end
  chan_id = nil
end

-- Quickfix buffer-local keymaps for stdin interaction.
-- Using autocmd because setqflist can recreate the buffer, losing buffer-local maps.
local qf_augroup = api.nvim_create_augroup('CompileQfInput', { clear = true })
api.nvim_create_autocmd('FileType', {
  group = qf_augroup,
  pattern = 'qf',
  callback = function(ev)
    vim.keymap.set('n', 'i', function()
      if not chan_alive() then
        vim.notify('No running compile job', vim.log.levels.WARN)
        return
      end
      local ok, input = pcall(vim.fn.input, 'stdin> ')
      if ok and input ~= '' then
        api.nvim_chan_send(chan_id, input .. '\n')
      end
    end, { buffer = ev.buf, nowait = true, desc = 'Send stdin to compile job' })

    vim.keymap.set('n', 'E', function()
      if not chan_alive() then
        vim.notify('No running compile job', vim.log.levels.WARN)
        return
      end
      api.nvim_chan_send(chan_id, '\x04')
    end, { buffer = ev.buf, nowait = true, desc = 'Send EOF to compile job' })
  end,
})

api.nvim_create_user_command('Compile', function(args)
  if not ansi_ns then
    ansi_ns = api.nvim_create_namespace('ansi_colors')
  end
  close_running()
  local cmd = #args.args > 0 and args.args or read_compile_command()
  if not cmd then
    -- No .env / COMPILE_COMMAND yet: offer to create one, then run it.
    local default = 'g++ -std=c++23 -Wall -Wextra -g %s -o /tmp/a.out && /tmp/a.out'
    local ok, input =
      pcall(vim.fn.input, { prompt = 'No COMPILE_COMMAND. Set one: ', default = default })
    input = ok and vim.trim(input) or ''
    if input == '' then
      vim.notify('No COMPILE_COMMAND found in .env', vim.log.levels.WARN)
      return
    end
    write_compile_command(input)
    cmd = input
  end
  local silent
  cmd, silent = strip_silent(cmd)
  compiler(cmd, api.nvim_buf_get_name(0), { silent = silent })
  -- NOTE: no `complete = 'file'`. File-type completion makes Vim treat the
  -- args as filenames and expand `%`/`#` (cmdline-special) *before* we see
  -- them, which would turn a typed `%s` into the current filename + 's'.
end, { nargs = '?' })

api.nvim_create_user_command('Recompile', function()
  if not ansi_ns then
    ansi_ns = api.nvim_create_namespace('ansi_colors')
  end
  close_running()
  if last_cmd then
    local cmd, silent = strip_silent(last_cmd)
    compiler(cmd, api.nvim_buf_get_name(0), { silent = silent })
  end
end, {})

-- Prompt for a compile command and save it to the project-root .env.
-- Usage: `:CompileSet g++ -g %s -o /tmp/a.out && /tmp/a.out`
--        `:CompileSet`  (opens a prompt prefilled with the current value)
api.nvim_create_user_command('CompileSet', function(args)
  local cmd = vim.trim(args.args)
  if cmd == '' then
    local default = read_compile_command()
      or 'g++ -std=c++17 -Wall -Wextra -g %s -o /tmp/a.out && /tmp/a.out'
    local ok, input = pcall(vim.fn.input, { prompt = 'COMPILE_COMMAND= ', default = default })
    cmd = ok and vim.trim(input) or ''
  end
  if cmd == '' then
    return
  end
  if write_compile_command(cmd) then
    last_cmd = cmd
  end
  -- No `complete = 'file'` here either: we want a literal `%s` placeholder
  -- written to .env, not Vim's current-file expansion.
end, { nargs = '?' })

return {
  custom = function(opts)
    compiler(opts.cmd, opts.fname, {
      silent = opts.silent,
      ondone = opts.ondone,
    })
  end,
}
