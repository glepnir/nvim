function load_completion()
  local timer = vim.loop.new_timer()
  local exit = false
  local i = 0
  timer:start(1000,100,vim.schedule_wrap(function()
    if i> 4 then
      exit = true
      timer:close()
    end
    i = i + 1
  end))

  while(exit)
  do
    print("here")
  end
end

