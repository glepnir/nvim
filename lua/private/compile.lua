local api = vim.api

local function parse_compiler_output(output)
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

  return qf_list
end

local function open_qf(stderr)
  local qf_list = parse_compiler_output(stderr)
  vim.fn.setqflist({}, 'r', {
    items = qf_list,
    quickfixtextfunc = function(info)
      local lines = {}
      local items = vim.fn.getqflist({ id = info.id, items = 1 }).items

      local last_bufnr = -1
      for i = info.start_idx, info.end_idx do
        local item = items[i]
        local filename = vim.fn.bufname(item.bufnr)
        if item.bufnr ~= last_bufnr then
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

    highlight QfFileName guifg=#e5c07b ctermfg=Yellow
    highlight QfLineCol guifg=#5c6370 ctermfg=DarkGray
    highlight QfErrorMsg guifg=#abb2bf ctermfg=White
    highlight QfContext guifg=#abb2bf ctermfg=White
  ]])

  vim.opt_local.number = false
  vim.opt_local.signcolumn = 'no'
end

local function compiler(compile_cmd, bufname, b_changedtick)
  if compile_cmd:find('%%s') then
    compile_cmd = compile_cmd:gsub('%%s', bufname)
  end
  vim.system(vim.split(compile_cmd, '%s'), { text = true }, function(out)
    vim.schedule(function()
      if api.nvim_buf_get_changedtick(0) ~= b_changedtick then
        return
      end
      if out.code ~= 0 and #out.stderr > 0 then
        open_qf(out.stderr)
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
