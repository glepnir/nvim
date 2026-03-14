local api = vim.api
local last_cmd = nil
local qf_id = nil
local ansi_ns = nil
local job = nil ---@type vim.SystemObj?

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

local function parse_err(text, save_item)
  local list = {}
  -- strip_ansi so patterns match even when compiler emits coloured output.
  local lines = vim.split(text, '\n', { trimempty = true })

  local i = 1
  local prev_item = {}
  while i <= #lines do
    local raw = lines[i]
    local line = clean(raw)

    local filename, lnum, col, type_str, msg = line:match('^([^:]+):(%d+):(%d+):%s*(%w+):%s*(.*)$')

    if filename and lnum and col then
      local bufnr = vim.fn.bufadd(filename)
      prev_item = {
        filename = filename,
        lnum = tonumber(lnum),
        col = tonumber(col),
        type = type_str:sub(1, 1):upper(),
        -- keep original raw line (with ANSI) as compile_info for coloured display
        text = type_str:lower() .. ': ' .. msg,
        bufnr = bufnr,
        -- store raw for the header extmark path
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
          -- compile_info: raw text keeps ANSI for extmark colouring.
          table.insert(list, {
            filename = prev_item.filename,
            bufnr = prev_item.bufnr,
            text = next_raw,
            lnum = prev_item.lnum, -- emm useful in some context
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
        -- "fname:lnum:col text"
        local line_text = string.format('%s:%s:%s %s', fname, lnum_s, col_s, item.text)
        table.insert(lines, line_text)

        -- filename highlight
        table.insert(line_colors, {
          lnum = i,
          start = 0,
          _end = #fname,
          color = nil, -- 用 hl_group 直接指定
          hl = 'QfFileName',
        })
        -- lnum:col highlight
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

  if curwin and api.nvim_win_is_valid(curwin) then
    api.nvim_set_current_win(curwin)
  end

  api.nvim_win_call(qf_win, function()
    apply_qf_syntax()
  end)
end

local function update_qf(qf_list, over)
  vim.fn.setqflist({}, 'a', {
    id = qf_id,
    items = qf_list,
    title = over and 'Compilation' or 'Compiling',
  })

  local qf_win = vim.fn.getqflist({ winid = 0 }).winid
  if qf_win ~= 0 and api.nvim_win_is_valid(qf_win) then
    api.nvim_win_call(qf_win, function()
      local count = api.nvim_buf_line_count(0)
      local cursor = api.nvim_win_get_cursor(qf_win)
      local height = api.nvim_win_get_height(qf_win)
      if cursor[1] >= count - height then
        api.nvim_win_set_cursor(qf_win, { count, 0 })
      end
      apply_qf_syntax()
    end)
  end
end

--- Wrap the compile command in script(1) to allocate a PTY.
--- Any compiler that checks isatty() will see a real terminal and emit
--- ANSI colours without needing any compiler-specific flags.
--- PTY merges stdout+stderr into a single stream on the master side,
--- so we only need to read stdout.  The PTY also injects \r before \n;
--- callers must strip_cr() the data.
local function make_cmd(compile_cmd)
  if vim.fn.has('win32') == 1 then
    return { 'cmd', '/c', compile_cmd }
  end
  if vim.fn.has('mac') == 1 then
    -- macOS script: script -q /dev/null sh -c CMD
    -- (no -e flag; exit code comes from the shell)
    return { 'script', '-q', '/dev/null', 'sh', '-c', compile_cmd }
  end
  -- Linux script: script -q -e -c CMD /dev/null
  -- -q  suppress "Script started/done" banners
  -- -e  propagate child exit code
  return { 'script', '-q', '-e', '-c', compile_cmd, '/dev/null' }
end

local function compiler(compile_cmd, bufname)
  if compile_cmd:find('%%s') then
    local cwd = vim.uv.cwd()
    if bufname:find(cwd, 1, true) then
      bufname = bufname:sub(#cwd + 2)
    end
    compile_cmd = compile_cmd:gsub('%%s', bufname)
  end
  last_cmd = compile_cmd
  open_qf_now(compile_cmd)

  local start_time = vim.uv.hrtime()
  -- PTY merges stdout+stderr → only one buffer needed.
  local out_buffer = ''
  local save_item = {}

  job = vim.system(make_cmd(compile_cmd), {
    text = true,
    stdout = function(err, data)
      if err or not data then
        return
      end
      vim.schedule(function()
        out_buffer = out_buffer .. strip_cr(data)
        local lines = vim.split(out_buffer, '\n', { plain = true })
        if not data:match('\n$') then
          out_buffer = lines[#lines]
          table.remove(lines, #lines)
        else
          out_buffer = ''
        end

        -- Route each line: diagnostic lines → parse_err, rest → compile_info.
        local plain_list = {}
        local err_text_lines = {}

        for _, line in ipairs(lines) do
          if line == '' then
            goto continue
          end
          -- A diagnostic header looks like "file:line:col: type: msg" after stripping ANSI.
          local stripped = clean(line)
          if
            stripped:match('^[^:]+:%d+:%d+:%s*%w+:')
            or stripped:match('^%s*%d+%s*|')
            or stripped:match('^%s*|')
            or stripped:match('^%s*%^')
            or stripped:match('generated')
          then
            table.insert(err_text_lines, line)
          else
            if #err_text_lines > 0 then
              local err_list = parse_err(table.concat(err_text_lines, '\n'), save_item)
              if #err_list > 0 then
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
          if #err_list > 0 then
            update_qf(err_list)
          end
        end
        if #plain_list > 0 then
          update_qf(plain_list)
        end
      end)
    end,
  }, function(out)
    local duration = (vim.uv.hrtime() - start_time) / 1e9
    vim.schedule(function()
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
      table.insert(list, { user_data = 'compile_info', text = ' ' })
      table.insert(list, {
        user_data = 'compile_info',
        text = ('Compilation %s at %s, duration %.3fs'):format(
          out.code ~= 0 and 'exited abnormally with code ' .. out.code or 'finished',
          os.date('%a %b %H:%M:%S'),
          duration
        ),
      })
      update_qf(list, true)
    end)
  end)
end

local function read_compile_command()
  local cwd = vim.uv.cwd()
  local env_file = vim.fs.joinpath(cwd, '.env')

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

local function close_running()
  if job and not job:is_closing() then
    job:kill('sigterm')
    vim.notify('close running job ' .. job.pid, vim.log.levels.WARN)
    job = nil
  end
end

api.nvim_create_user_command('Compile', function(args)
  if not ansi_ns then
    ansi_ns = api.nvim_create_namespace('ansi_colors')
  end
  close_running()
  local cmd = #args.args > 0 and args.args or read_compile_command()
  if cmd then
    compiler(cmd, api.nvim_buf_get_name(0))
  else
    vim.notify('No COMPILE_COMMAND found in .env', vim.log.levels.WARN)
  end
end, { nargs = '?', complete = 'file' })

api.nvim_create_user_command('Recompile', function()
  if not ansi_ns then
    ansi_ns = api.nvim_create_namespace('ansi_colors')
  end
  close_running()
  if last_cmd then
    compiler(last_cmd, api.nvim_buf_get_name(0))
  end
end, {})
