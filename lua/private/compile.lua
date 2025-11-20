local api = vim.api
local last_cmd = nil

--- Usage:
--- create .env file with COMPILE_COMMAND
--- eg: COMPILE_COMMAND=g++ --std=c++23 %s
--- %s mean current file

local function parse_compiler_output(output, code, duration)
  local qf_list = {}
  local lines = vim.split(output, '\n', { plain = true })

  local i = 1
  local prev_item = nil
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
      table.insert(qf_list, prev_item)

      local j = i + 1

      while j <= #lines do
        local next_line = lines[j]

        if
          next_line:match('^%s*%d+%s*|')
          or next_line:match('^%s*|')
          or next_line:match('^%s*%^')
          or next_line:match('generated')
        then
          table.insert(qf_list, {
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
      i = i + 1
    end
  end
  local info = {
    start = {
      user_data = 'compile_info',
      text = ('Compilation started at %s'):format(os.date('%a %b %H:%M:%S')),
    },
    fill = {
      user_data = 'compile_info',
      text = ' ',
    },
    _end = {
      user_data = 'compile_info',
      text = ('Compilation %s at %s, duration %fs'):format(
        code ~= 0 and 'exited abnormally with code ' .. code or 'finished',
        os.date('%a %b %H:%M:%S'),
        duration
      ) or '',
    },
  }
  qf_list = vim.list_extend({ info.start, info.fill }, qf_list)
  qf_list = vim.list_extend(qf_list, { info.fill, info._end })

  return qf_list
end

local function open_qf(stderr, code, duration)
  local qf_list = parse_compiler_output(stderr, code, duration)
  vim.fn.setqflist({}, 'r', {
    items = qf_list,
    quickfixtextfunc = function(info)
      local lines = {}
      local items = vim.fn.getqflist({ id = info.id, items = 1 }).items

      local last_bufnr = -1
      for i = info.start_idx, info.end_idx do
        local item = items[i]
        if item.user_data and item.user_data == 'compile_info' then
          table.insert(lines, item.text)
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
      return lines
    end,
  })
  vim.cmd.copen()
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

  vim.opt_local.number = false
  vim.opt_local.signcolumn = 'no'
  vim.opt_local.list = false
  vim.opt_local.colorcolumn = false
end

local function compiler(compile_cmd, bufname, b_changedtick)
  if compile_cmd:find('%%s') then
    compile_cmd = compile_cmd:gsub('%%s', bufname)
  end
  last_cmd = compile_cmd
  local start_time = vim.uv.hrtime()
  vim.system(vim.split(compile_cmd, '%s'), { text = true }, function(out)
    local duration = (vim.uv.hrtime() - start_time) / 1e9
    vim.schedule(function()
      if api.nvim_buf_get_changedtick(0) ~= b_changedtick then
        return
      end
      if out.code ~= 0 and #out.stderr > 0 then
        open_qf(out.stderr, out.code, duration)
      end
    end)
  end)
end

local function env_with_compile()
  local bufname = api.nvim_buf_get_name(0)
  local b_changedtick = api.nvim_buf_get_changedtick(0)
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
        compiler(cmd, bufname, b_changedtick)
      end
    end)
  end)()
end

api.nvim_create_user_command('Compile', function()
  env_with_compile()
end, {})

api.nvim_create_user_command('Recompile', function()
  if last_cmd then
    local bufname = api.nvim_buf_get_name(0)
    local b_changedtick = api.nvim_buf_get_changedtick(0)
    compiler(last_cmd, bufname, b_changedtick)
  end
end, {})
