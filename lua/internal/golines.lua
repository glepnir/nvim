local uv,api = vim.loop,vim.api
local stdin = uv.new_pipe(true)
local stdout = uv.new_pipe(false)
local stderr = uv.new_pipe(false)

local golines_format = function()
  if api.nvim_buf_get_option(0,'filetype') ~= 'go' then return end
  local file = api.nvim_buf_get_name(0)

  local handle, pid = uv.spawn("golines", {
    stdio = {stdin, stdout, stderr},
    args = {"--max-len=80",file}
  }, function(code, signal) -- on exit
  end)

  uv.read_start(stdout, vim.schedule_wrap(function(err, data)
    assert(not err, err)
    if data then
      local content = {}
      local index = 1
      for s in data:gmatch("[^\n]+") do
        table.insert(content,s)
        if s == '}' or s == ')' or s:match('^import') or index == 1 then
          table.insert(content,'')
        end
        index = index + 1
      end
      api.nvim_buf_set_lines(0,0,10,true,content)
      api.nvim_command('write')
    end
  end))


  uv.read_start(stderr, function(err, data)
    assert(not err, err)
    if data then
      print("stderr chunk", stderr, data)
    end
  end)

  uv.shutdown(stdin, function()
    uv.close(handle, function()
    end)
  end)
end

return { golines_format = golines_format }
