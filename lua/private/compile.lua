local api = vim.api
local last_cmd = nil
local qf_id = nil
local ansi_ns = nil

local function parse_err(stderr, save_item)
  local list = {}
  local lines = vim.split(stderr, '\n', { trimempty = true })

  local i = 1
  local prev_item = {}
  while i <= #lines do
    local line = lines[i]

    local filename, lnum, col, type_str, msg = line:match('^([^:]+):(%d+):(%d+):%s*(%w+):%s*(.*)$')
    local bufnr = vim.fn.bufadd(filename)

    if filename and lnum and col then
      prev_item = {
        filename = filename,
        lnum = tonumber(lnum),
        col = tonumber(col),
        type = type_str:sub(1, 1):upper(),
        text = msg,
        bufnr = bufnr,
      }
      table.insert(list, prev_item)
      save_item.lnum = prev_item.lnum
      save_item.col = prev_item.col
      save_item.bufnr = prev_item.bufnr

      local j = i + 1

      while j <= #lines do
        local next_line = lines[j]

        if
          next_line:match('^%s*%d+%s*|')
          or next_line:match('^%s*|')
          or next_line:match('^%s*%^')
          or next_line:match('generated')
        then
          table.insert(list, {
            filename = prev_item.filename,
            bufnr = prev_item.bufnr,
            text = next_line,
          })
          j = j + 1
        else
          break
        end
      end

      i = j
    else
      if save_item then
        table.insert(list, {
          filename = save_item.filename,
          bufnr = save_item.bufnr,
          lnum = save_item.lnum,
          col = save_item.col,
          text = line,
          user_data = 'compile_info',
        })
      end
      i = i + 1
    end
  end

  return list
end

local function apply_qf_syntax()
  vim.cmd([[
    syntax clear
    syntax match QfFileName /^▸ \zs[^ ]*/ 
    syntax match QfLineCol / \d\+:\d\+/
    syntax match QfErrorMsg /use.*$/
    syntax match QfContext /^  .*/
    syntax match QfFinish /\<finished\>/
    syntax match QfExit /\<exited abnormally\>/
    syntax match QfCode /\vcode\s+\zs\d+/

    highlight QfFileName guifg=#992c3d ctermfg=Red gui=bold,underline
    highlight QfLineCol guifg=#c7c938 ctermfg=Yellow
    highlight QfErrorMsg guifg=#abb2bf ctermfg=White
    highlight QfContext guifg=#abb2bf ctermfg=White
    highlight QfFinish guifg=#62c92a ctermfg=Green
    highlight QfExit guifg=#992c3d ctermfg=Red gui=bold
    highlight QfCode guifg=#992c3d ctermfg=Red gui=bold
  ]])
end

local info_list = {
  start = {
    user_data = 'compile_info',
  },
  fill = {
    user_data = 'compile_info',
    text = ' ',
  },
  cmd = {
    user_data = 'compile_info',
  },
}

local function update_qf(qf_list, over)
  local line_colors = {}
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

  vim.fn.setqflist({}, 'a', {
    items = qf_list,
    title = over and 'Compilation' or 'Compiling',
    quickfixtextfunc = function(info)
      local lines = {}
      qf_id = info.id
      local res = vim.fn.getqflist({ id = info.id, items = 1, winid = 0 })
      local items = res.items
      local last_bufnr = -1

      for i = info.start_idx, info.end_idx do
        local item = items[i]
        if item.user_data and item.user_data == 'compile_info' then
          if item.text:find('\27%[%d+m') then
            local plain = ''
            local pos = 1

            for match_start, code, match_end in item.text:gmatch('()\27%[(%d+)m()') do
              plain = plain .. item.text:sub(pos, match_start - 1)
              if ansi_colors[tostring(code)] then
                table.insert(line_colors, {
                  lnum = i,
                  start = match_start,
                  _end = match_end,
                  color = ansi_colors[tostring(code)],
                })
              end
              pos = match_end
            end
            plain = plain .. item.text:sub(pos)

            table.insert(lines, plain)
          else
            table.insert(lines, item.text)
          end
        elseif item.bufnr ~= last_bufnr then
          local filename = vim.fn.bufname(item.bufnr)
          table.insert(
            lines,
            string.format('▸ %s %d:%d %s', filename, item.lnum, item.col, item.text)
          )
          last_bufnr = item.bufnr
        else
          table.insert(lines, string.format('  %s', item.text))
        end
      end
      local buf = api.nvim_win_get_buf(res.winid)
      if #line_colors > 0 then
        vim.schedule(function()
          for _, conf in ipairs(line_colors) do
            api.nvim_set_hl(
              ansi_ns,
              'ANSI' .. conf.color,
              { ctermfg = tonumber(conf.code), fg = 'Green' }
            )
            api.nvim_buf_set_extmark(buf, ansi_ns, conf.lnum - 1, conf.start - 1, {
              end_col = conf._end,
              hl_group = 'ANSI' .. conf.color,
            })
          end
        end)
      end
      return lines
    end,
  })

  local qf_win = vim.fn.getqflist({ winid = 0 }).winid
  local curwin
  if qf_win == 0 then
    curwin = api.nvim_get_current_win()
    vim.cmd.copen()
    qf_win = api.nvim_get_current_win()
    api.nvim_win_set_hl_ns(qf_win, ansi_ns)
    vim.opt_local.number = false
    vim.opt_local.signcolumn = 'no'
    vim.opt_local.list = false
    vim.bo.textwidth = 0
  end

  if curwin and api.nvim_win_is_valid(curwin) then
    api.nvim_set_current_win(curwin)
  end

  api.nvim_win_call(qf_win, function()
    local count = api.nvim_buf_line_count(0)
    local height = api.nvim_win_get_height(qf_win)
    if count > height then
      api.nvim_win_set_cursor(qf_win, { count, 0 })
    end
    apply_qf_syntax()
  end)
end

local function compiler(compile_cmd, bufname)
  if compile_cmd:find('%%s') then
    local cwd = vim.uv.cwd()
    if bufname:find(cwd) then
      bufname = bufname:sub(#cwd + 2)
    end
    compile_cmd = compile_cmd:gsub('%%s', bufname)
  end
  last_cmd = compile_cmd

  local start_time = vim.uv.hrtime()

  local stdout_buffer = ''
  local stderr_buffer = ''
  local save_item = {}

  info_list.cmd.text = last_cmd
  info_list.start.text = ('Compilation started at %s'):format(os.date('%a %b %H:%M:%S'))
  vim.schedule(function()
    local action = 'a'
    local qf_win
    if qf_id then
      qf_win = vim.fn.getqflist({ id = qf_id, winid = true }).winid
      if api.nvim_win_is_valid(qf_win) then
        action = 'r'
      end
    end
    vim.fn.setqflist({}, action, {
      title = 'Compiling',
      id = qf_id,
      items = { info_list.start, info_list.fill, info_list.cmd },
    })

    if action == 'r' then
      api.nvim_win_call(qf_win, function()
        apply_qf_syntax()
      end)
    end
  end)

  vim.system({ 'sh', '-c', compile_cmd }, {
    text = true,
    stdout = function(err, data)
      if err or not data then
        return
      end

      vim.schedule(function()
        stdout_buffer = stdout_buffer .. data
        local lines = vim.split(stdout_buffer, '\n', { plain = true })
        if not data:match('\n$') then
          stdout_buffer = lines[#lines]
          table.remove(lines, #lines)
        else
          stdout_buffer = ''
        end

        local list = {}
        for _, line in ipairs(lines) do
          if line ~= '' then
            table.insert(list, {
              text = line,
              user_data = 'compile_info',
            })
          end
        end

        update_qf(list)
      end)
    end,

    stderr = function(err, data)
      if err or not data then
        return
      end

      vim.schedule(function()
        stderr_buffer = stderr_buffer .. data
        local lines = vim.split(stderr_buffer, '\n', { plain = true })
        if not data:match('\n$') then
          stderr_buffer = lines[#lines]
          table.remove(lines, #lines)
        else
          stderr_buffer = ''
        end

        local list = {}
        local err_text = table.concat(lines, '\n')
        if err_text ~= '' then
          local err_list = parse_err(err_text, save_item)
          vim.list_extend(list, err_list)
          update_qf(list)
        end
      end)
    end,
  }, function(out)
    local duration = (vim.uv.hrtime() - start_time) / 1e9
    vim.schedule(function()
      local list = {}
      if stdout_buffer ~= '' then
        table.insert(list, {
          text = stdout_buffer,
          user_data = 'compile_info',
        })
      end

      if stderr_buffer ~= '' then
        local err_list = parse_err(stderr_buffer)
        vim.list_extend(list, err_list)
      end

      table.insert(list, {
        user_data = 'compile_info',
        text = ' ',
      })
      table.insert(list, {
        user_data = 'compile_info',
        text = ('Compilation %s at %s, duration %fs'):format(
          out.code ~= 0 and 'exited abnormally with code ' .. out.code or 'finished',
          os.date('%a %b %H:%M:%S'),
          duration
        ),
      })

      update_qf(list, true)
    end)
  end)
end

local function env_with_compile()
  local bufname = api.nvim_buf_get_name(0)
  local cwd = vim.uv.cwd()
  local env_file = vim.fs.joinpath(cwd, '.env')
  coroutine.wrap(function()
    local co = assert(coroutine.running())
    vim.uv.fs_open(env_file, 'r', 438, function(err, fd)
      assert(not err)
      coroutine.resume(co, fd)
    end)
    local fd = coroutine.yield()

    vim.uv.fs_fstat(fd, function(err, stat)
      assert(not err)
      coroutine.resume(co, stat.size)
    end)
    local size = coroutine.yield()
    if size == 0 then
      return
    end

    vim.uv.fs_read(fd, size, 0, function(err, data)
      assert(not err)
      local lines = vim.split(data, '\n')
      local cmd = nil
      for _, line in ipairs(lines) do
        if line:find('^COMPILE_COMMAND') then
          cmd = line:sub(17, #line)
          break
        end
      end
      if cmd then
        compiler(cmd, bufname)
      end
    end)
  end)()
end

api.nvim_create_user_command('Compile', function()
  if not ansi_ns then
    ansi_ns = api.nvim_create_namespace('ansi_colors')
  end
  env_with_compile()
end, {})

api.nvim_create_user_command('Recompile', function()
  if last_cmd then
    local bufname = api.nvim_buf_get_name(0)
    compiler(last_cmd, bufname)
  end
end, {})
