local uv, api = vim.loop, vim.api
local fmt = {}

local function get_format_opts()
  local file_name = api.nvim_buf_get_name(0)
  local fmt_tools = {
    go = {
      cmd = 'golines',
      args = { '--max-len=100', file_name },
    },
    lua = {
      cmd = 'stylua',
      args = { '-' },
    },
  }

  if fmt_tools[vim.bo.filetype] then
    return fmt_tools[vim.bo.filetype]
  end
  return nil
end

local check_same = function(tbl1, tbl2)
  if #tbl1 ~= #tbl2 then
    return false
  end
  for k, v in ipairs(tbl1) do
    if v ~= tbl2[k] then
      return false
    end
  end
  return true
end

local function safe_close(handle)
  if not uv.is_closing(handle) then
    uv.close(handle)
  end
end

function fmt:format_file(err, data)
  assert(not err, err)
  if data then
    local new_lines = vim.split(data, '\n')
    if string.len(new_lines[#new_lines]) == 0 then
      table.remove(new_lines, #new_lines)
    end

    if not check_same(self.old_lines, new_lines) then
      api.nvim_buf_set_lines(0, 0, -1, false, new_lines)
      api.nvim_command('write')
      self.old_lines = new_lines
    end
  end
end

function fmt:get_current_lines()
  self.old_lines = api.nvim_buf_get_lines(0, 0, -1, false)
end

function fmt:new_spawn(opts)
  local stdout = uv.new_pipe(false)
  local stderr = uv.new_pipe(false)
  local stdin = uv.new_pipe(false)

  self.handle, self.pid = uv.spawn(opts.cmd, {
    args = opts.args,
    stdio = { stdin, stdout, stderr },
  }, function(_, _)
    uv.read_stop(stdout)
    uv.read_stop(stderr)
    safe_close(self.handle)
    safe_close(stdout)
    safe_close(stderr)
  end)

  uv.read_start(
    stdout,
    vim.schedule_wrap(function(err, data)
      self:format_file(err, data)
    end)
  )

  uv.read_start(stderr, function(err, _)
    assert(not err, err)
  end)

  if opts.filetype == 'lua' and opts.contents then
    uv.write(stdin, opts.contents)
  end
  uv.shutdown(stdin, function()
    safe_close(stdin)
  end)
end

function fmt:formatter()
  fmt:get_current_lines()
  local opts = get_format_opts()
  opts.filetype = vim.bo.filetype
  if vim.bo.filetype == 'lua' then
    opts.contents = {}
    for _, v in pairs(self.old_lines) do
      table.insert(opts.contents, v .. '\n')
    end
  end
  if opts ~= nil then
    fmt:new_spawn(opts)
  end
end

return fmt
