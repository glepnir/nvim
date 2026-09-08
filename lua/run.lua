local api = vim.api

-- Created eagerly: the exported `custom()` entry point used to reach
-- open_qf_now() with a nil namespace because only :Compile/:Recompile
-- initialised it lazily.
local ansi_ns = api.nvim_create_namespace('compile_ansi_colors')

local last_cmd = nil ---@type string?
local last_silent = false
local qf_id = nil ---@type integer?
local chan_id = nil ---@type integer?
local job_cwd = nil ---@type string?
local file_cache = {} ---@type table<string, boolean>

-- Monotonic job counter. A job is "superseded" once a newer one starts;
-- superseded jobs must not write to the new job's quickfix list.
local job_seq = 0
local active_seq = 0

--- Strip ANSI escape sequences from a string.
local function strip_ansi(s)
  return (s:gsub('\27%[[%d;]*m', ''))
end

--- Apply backspace-overwrite semantics. `.` matches newlines in Lua patterns,
--- so a BS at the start of a line would otherwise eat the preceding newline
--- and join two lines together.
local function strip_bs(s)
  if not s:find('\8', 1, true) then
    return s
  end
  local prev
  local guard = 0
  repeat
    prev = s
    s = s:gsub('[^\n]\8', '')
    guard = guard + 1
  until s == prev or guard > 64
  return (s:gsub('\8', ''))
end

--- Apply carriage-return semantics to a raw byte stream.
--- CRLF is a line break (the PTY line discipline adds the CR); a *lone* CR
--- means "return to column 0 and overwrite", which is how progress bars work.
--- Deleting CRs outright made every progress update accumulate into one
--- ever-growing line that was never flushed.
local function normalize_cr(s)
  s = s:gsub('\r\n', '\n')
  s = s:gsub('[^\n\r]*\r', '')
  return s
end

--- Normalise a single line for pattern matching. CR is already gone by the
--- time a line reaches here; the control-char class removes the rest.
local function clean(s)
  s = strip_bs(s)
  s = strip_ansi(s)
  s = s:gsub('[%z\1-\8\11-\31\127]', '')
  return s
end

--- Resolve a path reported by the compiler against the job's working
--- directory. Returns nil when it does not name an existing file, so we never
--- `bufadd()` junk like `Result` out of a line such as `Result: 3:4: ok: done`.
local function resolve_file(f)
  local cached = file_cache[f]
  if cached ~= nil then
    return cached or nil
  end
  local path = f
  local absolute = f:sub(1, 1) == '/' or f:match('^%a:[/\\]') ~= nil
  if not absolute and job_cwd then
    path = vim.fs.joinpath(job_cwd, f)
  end
  local stat = vim.uv.fs_stat(path)
  local resolved = (stat and stat.type == 'file') and vim.fs.normalize(path) or false
  file_cache[f] = resolved
  return resolved or nil
end

--- Match a compiler diagnostic header line: `file:line:col: type: msg`.
--- Tries a Windows drive-letter path first (e.g. C:\src\main.cpp:5:1),
--- then falls back to the generic (Unix) form. Returns all-or-nothing.
--- This stays purely syntactic; existence of the file is checked separately.
local function match_diag(line)
  local f, l, c, t, m = line:match('^(%a:[/\\][^:]+):(%d+):(%d+):%s*(%w+):%s*(.*)$')
  if not f then
    f, l, c, t, m = line:match('^([^:]+):(%d+):(%d+):%s*(%w+):%s*(.*)$')
  end
  return f, l, c, t, m
end

--- gcc/clang summary line: `1 warning generated.`, `2 warnings and 1 error
--- generated.`. Anchored, so ordinary output like `Report generated` is not
--- swallowed into the previous diagnostic block any more.
local function is_summary(s)
  return s:match('^%s*%d+ .-generated%.?%s*$') ~= nil
end

--- Source-quote / caret lines that belong to the diagnostic above them.
local function is_continuation(s)
  return s:match('^%s*%d+%s*|') ~= nil
    or s:match('^%s*|') ~= nil
    or s:match('^%s*%^') ~= nil
    or is_summary(s)
end

--- True for any line that should be routed through parse_err().
local function is_diag_like(s)
  return match_diag(s) ~= nil or is_continuation(s)
end

local function parse_err(text, save_item)
  local list = {}
  local lines = vim.split(text, '\n', { trimempty = true })

  local i = 1
  while i <= #lines do
    local raw = lines[i]
    local line = clean(raw)

    local filename, lnum, col, type_str, msg = match_diag(line)
    local resolved = filename and resolve_file(filename) or nil

    if resolved then
      local bufnr = vim.fn.bufadd(resolved)
      local item = {
        filename = resolved,
        lnum = tonumber(lnum),
        col = tonumber(col),
        type = type_str:sub(1, 1):upper(),
        text = type_str:lower() .. ': ' .. msg,
        bufnr = bufnr,
      }
      table.insert(list, item)
      if save_item then
        save_item.lnum = item.lnum
        save_item.col = item.col
        save_item.bufnr = item.bufnr
        save_item.filename = item.filename
      end

      local j = i + 1
      while j <= #lines do
        local next_raw = lines[j]
        if is_continuation(clean(next_raw)) then
          table.insert(list, {
            filename = item.filename,
            bufnr = item.bufnr,
            text = next_raw,
            lnum = item.lnum,
            col = item.col,
            user_data = 'compile_info',
          })
          j = j + 1
        else
          break
        end
      end
      i = j
    elseif filename then
      -- Looked like a diagnostic but the path does not exist (`<built-in>`,
      -- a false positive, or output from a different cwd). Keep the text, but
      -- do not create a buffer or a jump target for it.
      if save_item then
        save_item.bufnr = nil
        save_item.filename = nil
      end
      table.insert(list, { text = raw, user_data = 'compile_info' })
      i = i + 1
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
    local items = res.items or {}

    for i = info.start_idx, info.end_idx do
      local item = items[i]

      if not item then
        table.insert(lines, '')
      elseif item.user_data == 'compile_info' then
        local segs = grammar:match(strip_bs(item.text or '')) or {}
        local plain = {}
        local len = 0 -- running byte length; concat-per-segment was O(n^2)
        local active = nil

        for _, seg in ipairs(segs) do
          if seg.type == 'code' then
            local c = seg.value
            if c ~= '0' and ansi_colors[c] then
              if active then
                active._end = len
              end
              active = {
                lnum = i,
                start = len,
                color = ansi_colors[c],
                code = tonumber(c),
              }
              table.insert(line_colors, active)
            else
              if active then
                active._end = len
                active = nil
              end
            end
          else
            table.insert(plain, seg.value)
            len = len + #seg.value
          end
        end

        if active then
          active._end = len
        end
        table.insert(lines, table.concat(plain))
      elseif item.bufnr ~= 0 then
        -- ':.' keeps the short, familiar `src/main.c` form now that items
        -- carry a canonical absolute path.
        local fname = vim.fn.fnamemodify(vim.fn.bufname(item.bufnr), ':.')
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

    if #line_colors > 0 and res.winid ~= 0 and api.nvim_win_is_valid(res.winid) then
      local buf = api.nvim_win_get_buf(res.winid)
      local first, last = info.start_idx, info.end_idx
      vim.schedule(function()
        if not api.nvim_buf_is_valid(buf) then
          return
        end
        -- Vim re-invokes quickfixtextfunc for the same items on every redraw.
        -- Without this the namespace accumulated a duplicate extmark per
        -- render, forever.
        local count = api.nvim_buf_line_count(buf)
        local s = math.max(first - 1, 0)
        local e = math.min(last, count)
        if s < e then
          pcall(api.nvim_buf_clear_namespace, buf, ansi_ns, s, e)
        end
        for _, c in ipairs(line_colors) do
          local hl_group = c.hl or ('ANSI' .. tostring(c.color))
          if c.color then
            -- cterm wants a palette index (0-7), not the SGR code (30-37).
            api.nvim_set_hl(ansi_ns, hl_group, { ctermfg = c.code - 30, fg = c.color })
          end
          pcall(api.nvim_buf_set_extmark, buf, ansi_ns, c.lnum - 1, c.start, {
            end_col = c._end,
            hl_group = hl_group,
          })
        end
      end)
    end

    return lines
  end
end

--- The quickfix window, but only when it is actually showing *our* list.
--- After an unrelated `:grep` the window displays someone else's list and we
--- must not scroll it or re-apply our syntax to it.
local function qf_window()
  local win = vim.fn.getqflist({ winid = 0 }).winid
  if win == 0 or not api.nvim_win_is_valid(win) then
    return nil
  end
  if not qf_id or vim.fn.getqflist({ nr = 0, id = 0 }).id ~= qf_id then
    return nil
  end
  return win
end

local function ensure_hl_ns(win)
  pcall(api.nvim_win_set_hl_ns, win, ansi_ns)
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
    local qf_buf = api.nvim_win_get_buf(qf_win)
    vim.wo[qf_win].number = false
    vim.wo[qf_win].signcolumn = 'no'
    vim.wo[qf_win].list = false
    vim.wo[qf_win].listchars = ''
    vim.bo[qf_buf].textwidth = 0
  end

  -- Unconditionally: if the user had already :copen'd the window themselves,
  -- the namespace was never attached and every ANSI colour was silently lost.
  ensure_hl_ns(qf_win)

  do
    local qf_buf = api.nvim_win_get_buf(qf_win)
    local count = api.nvim_buf_line_count(qf_buf)
    if count > 0 then
      pcall(api.nvim_win_set_cursor, qf_win, { count, 0 })
    end
  end

  if curwin and api.nvim_win_is_valid(curwin) then
    api.nvim_set_current_win(curwin)
  end

  api.nvim_win_call(qf_win, function()
    apply_qf_syntax()
  end)
end

--- Append by list id. The quickfix stack only holds 10 lists, so a long build
--- plus a few `:grep`s used to push our list off the end and setqflist() then
--- failed silently, dropping the rest of the output on the floor.
local function append_qf(items, title)
  if qf_id and vim.fn.setqflist({}, 'a', { id = qf_id, items = items, title = title }) == 0 then
    return
  end
  vim.fn.setqflist({}, ' ', {
    title = title,
    items = items,
    quickfixtextfunc = make_qf_textfunc(),
  })
  qf_id = vim.fn.getqflist({ nr = '$', id = 0 }).id
end

local function update_qf(qf_list, over)
  -- Snapshot "was tailing" BEFORE setqflist changes count.
  local win = qf_window()
  local was_tailing = false
  if win then
    local buf = api.nvim_win_get_buf(win)
    local old_count = api.nvim_buf_line_count(buf)
    local cursor = api.nvim_win_get_cursor(win)
    was_tailing = cursor[1] >= old_count
  end

  append_qf(qf_list, over and 'Compilation' or 'Compiling')

  win = qf_window()
  if not win then
    return
  end
  ensure_hl_ns(win)
  api.nvim_win_call(win, function()
    if was_tailing or over then
      local count = api.nvim_buf_line_count(0)
      if count > 0 then
        pcall(api.nvim_win_set_cursor, win, { count, 0 })
      end
      if over then
        local save = vim.wo[win].scrolloff
        vim.wo[win].scrolloff = 999
        vim.cmd('normal! zz')
        vim.wo[win].scrolloff = save
      end
    end
    apply_qf_syntax()
  end)
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

local function make_cmd(compile_cmd)
  if vim.fn.has('win32') == 1 then
    return compile_cmd
  end
  -- jobstart with pty=true handles PTY allocation, no need for script(1).
  return { 'sh', '-c', compile_cmd }
end

local function run(compile_cmd, bufname, opts)
  opts = opts or {}
  -- The command comes from the root .env, so run it there too. Previously it
  -- ran in Neovim's cwd, which broke relative paths in the command and made
  -- the diagnostics' relative paths unresolvable.
  local root = find_root()

  if compile_cmd:find('%%s') then
    local name = bufname or ''
    if name == '' then
      vim.notify('%s in COMPILE_COMMAND but the buffer has no file name', vim.log.levels.WARN)
    else
      -- startswith, not find(): find() matched anywhere, so /tmp/home/u/p/x.c
      -- got mangled when the root happened to be /home/u/p.
      if vim.startswith(name, root .. '/') or vim.startswith(name, root .. '\\') then
        name = name:sub(#root + 2)
      end
      -- Quote it: an unescaped path with spaces used to split into two args.
      name = vim.fn.shellescape(name)
    end
    -- Function replacement: a literal '%' in the path can't corrupt the
    -- gsub replacement string this way (a plain string repl would error).
    compile_cmd = compile_cmd:gsub('%%s', function()
      return name
    end)
  end

  last_cmd = compile_cmd
  last_silent = opts.silent and true or false
  job_cwd = root
  file_cache = {}

  -- Claim the active slot *before* open_qf_now() replaces qf_id, so that a
  -- previously stopped job is already superseded by the time its callbacks
  -- run - even if jobstart() below fails outright.
  job_seq = job_seq + 1
  local my_seq = job_seq
  active_seq = my_seq

  if not opts.silent then
    open_qf_now(compile_cmd)
  end

  local start_time = vim.uv.hrtime()
  local save_item = {}
  local job_id ---@type integer?

  -- Stream state. line_buf holds the current, still incomplete line; cr_held
  -- remembers a trailing CR that might be the first half of a CRLF split
  -- across two chunks.
  local line_buf = ''
  local cr_held = false
  -- Text of the current partial line that has already been pushed to the
  -- quickfix list by the idle flush, so we do not print it twice.
  local shown_partial = nil ---@type string?
  local idle_timer = vim.uv.new_timer()

  --- A job that was jobstop()'d in favour of a newer one must not touch the
  --- newer job's quickfix list, chan_id, or ondone callback. A job that was
  --- merely cancelled (no successor) still reports its own exit.
  local function superseded()
    return active_seq ~= my_seq
  end

  local function emit(items)
    if opts.silent or superseded() or #items == 0 then
      return
    end
    update_qf(items)
  end

  --- Split freshly arrived bytes into complete lines, returning them and
  --- leaving any trailing partial line in line_buf.
  local function feed(chunk)
    local s = line_buf .. (cr_held and '\r' or '') .. chunk
    cr_held = false
    if s:sub(-1) == '\r' then
      s = s:sub(1, -2)
      cr_held = true
    end
    s = normalize_cr(s)
    local lines = vim.split(s, '\n', { plain = true })
    line_buf = table.remove(lines) or ''
    return lines
  end

  --- Drop the prefix already shown by the idle flush from the first completed
  --- line. If the line was overwritten by a CR in the meantime the prefix will
  --- not match and we just print the new text.
  local function drop_shown(lines)
    -- Note: sampled before the possible table.remove() below, otherwise a
    -- chunk whose only completed line was fully shown already would leave a
    -- stale prefix behind for the next chunk.
    local completed = #lines > 0
    if shown_partial and completed then
      local first = lines[1]
      if vim.startswith(first, shown_partial) then
        local rest = first:sub(#shown_partial + 1)
        if rest == '' then
          table.remove(lines, 1)
        else
          lines[1] = rest
        end
      end
    end
    if completed then
      shown_partial = nil
    end
    return lines
  end

  local function process(lines)
    local out = {}
    local errs = {}

    local function flush_errs()
      if #errs > 0 then
        vim.list_extend(out, parse_err(table.concat(errs, '\n'), save_item))
        errs = {}
      end
    end

    for _, line in ipairs(lines) do
      if line == '' then
        -- Blank lines used to be dropped entirely, which flattened the
        -- program's own paragraph spacing.
        flush_errs()
        save_item.bufnr = nil
        save_item.filename = nil
        table.insert(out, { text = ' ', user_data = 'compile_info' })
      elseif is_diag_like(clean(line)) then
        table.insert(errs, line)
      else
        flush_errs()
        -- An ordinary line ends the diagnostic block, so later continuation
        -- lines must not inherit its (now stale) file/line.
        save_item.bufnr = nil
        save_item.filename = nil
        table.insert(out, { text = line, user_data = 'compile_info' })
      end
    end
    flush_errs()

    return out
  end

  --- Show a line that has no newline yet, e.g. a `printf("Enter n: ")` prompt.
  --- Without this the prompt sat in the buffer until the process exited, which
  --- made the `i` (send stdin) mapping useless.
  local function flush_partial()
    if opts.silent or superseded() or line_buf == '' then
      return
    end
    local text = line_buf
    if shown_partial and vim.startswith(text, shown_partial) then
      local rest = text:sub(#shown_partial + 1)
      if rest == '' then
        return
      end
      update_qf({ { text = rest, user_data = 'compile_info' } })
    else
      update_qf({ { text = text, user_data = 'compile_info' } })
    end
    shown_partial = text
  end

  local function arm_idle_timer()
    if not idle_timer or opts.silent then
      return
    end
    idle_timer:stop()
    if line_buf ~= '' then
      idle_timer:start(120, 0, function()
        vim.schedule(flush_partial)
      end)
    end
  end

  job_id = vim.fn.jobstart(make_cmd(compile_cmd), {
    pty = true,
    cwd = root,
    on_stdout = function(_, data, _)
      -- jobstart with pty=true delivers data as a list of strings (split on \n).
      -- Join them back; empty trailing element means the chunk ended with \n.
      if not data or (#data == 1 and data[1] == '') then
        return
      end
      local raw = table.concat(data, '\n')

      vim.schedule(function()
        if superseded() then
          return
        end
        local lines = drop_shown(feed(raw))
        if #lines > 0 then
          emit(process(lines))
        end
        arm_idle_timer()
      end)
    end,

    on_exit = function(_, exit_code, _)
      local duration = (vim.uv.hrtime() - start_time) / 1e9
      vim.schedule(function()
        if idle_timer then
          idle_timer:stop()
          if not idle_timer:is_closing() then
            idle_timer:close()
          end
          idle_timer = nil
        end

        local mine = not superseded()
        -- Only clear chan_id if we are still the active job. A job that was
        -- jobstop()'d earlier must not null out the freshly started one.
        if chan_id == job_id then
          chan_id = nil
        end

        if mine and not opts.silent then
          local list = {}
          if line_buf ~= '' or cr_held then
            local tail = drop_shown(feed('\n'))
            vim.list_extend(list, process(tail))
          end
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

        if mine and opts.ondone then
          opts.ondone(exit_code)
        end
      end)
    end,
  })

  if not job_id or job_id <= 0 then
    vim.notify('Failed to start job: ' .. compile_cmd, vim.log.levels.ERROR)
    if idle_timer then
      idle_timer:stop()
      if not idle_timer:is_closing() then
        idle_timer:close()
      end
      idle_timer = nil
    end
    return
  end

  chan_id = job_id
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

local function send(data)
  if not chan_alive() then
    vim.notify('No running compile job', vim.log.levels.WARN)
    return
  end
  -- The channel can die between the liveness check and the send.
  local ok, err = pcall(api.nvim_chan_send, chan_id, data)
  if not ok then
    vim.notify('Failed to send to compile job: ' .. tostring(err), vim.log.levels.WARN)
  end
end

local function stop()
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
        send(input .. '\n')
      end
    end, { buffer = ev.buf, nowait = true, desc = 'Send stdin to compile job' })

    vim.keymap.set('n', 'E', function()
      send('\x04')
    end, { buffer = ev.buf, nowait = true, desc = 'Send EOF to compile job' })
  end,
})
api.nvim_create_user_command('Run', function(args)
  stop()
  if vim.trim(args.args) == '' then
    vim.notify('A command is required', vim.log.levels.WARN)
    return
  end
  local cmd, silent = strip_silent(args.args)
  run(cmd, api.nvim_buf_get_name(0), { silent = silent })
end, { nargs = '?' })

api.nvim_create_user_command('Rerun', function()
  if not last_cmd then
    vim.notify('Nothing to rerun yet', vim.log.levels.WARN)
    return
  end
  stop()
  run(last_cmd, api.nvim_buf_get_name(0), { silent = last_silent })
end, {})

return {
  run = run,
  stop = stop,
  send = send,
  find_root = find_root,
  strip_silent = strip_silent,
  rerun = function()
    if not last_cmd then
      vim.notify('Nothing to recompile yet', vim.log.levels.WARN)
      return
    end
    stop()
    run(last_cmd, api.nvim_buf_get_name(0), { silent = last_silent })
  end,
  remember = function(cmd, silent)
    last_cmd = cmd
    last_silent = silent and true or false
  end,
}
