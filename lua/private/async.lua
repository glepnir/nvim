-- Result type to handle errors properly
local Result = {}
Result.__index = Result

function Result.success(value)
  return setmetatable({ success = true, value = value, error = nil }, Result)
end

function Result.failure(err)
  return setmetatable({ success = false, value = nil, error = err }, Result)
end

-- Wrap a function to return a promise
function _G.awrap(func)
  return function(...)
    local args = { ... }
    return function(callback)
      local function handle_result(...)
        local results = { ... }
        if #results == 0 then
          -- No results
          callback(Result.success(nil))
        elseif #results == 1 then
          -- Single result
          callback(Result.success(results[1]))
        else
          -- Multiple results
          callback(Result.success(results))
        end
      end

      -- Handle any errors in the wrapped function
      local status, err = pcall(function()
        table.insert(args, handle_result)
        func(unpack(args))
      end)

      if not status then
        callback(Result.failure(err))
      end
    end
  end
end

-- Wrap vim.system to provide better error handling and cleaner usage
function _G.asystem(cmd, opts)
  opts = opts or {}
  return function(callback)
    local progress_data = {}
    local error_data = {}
    local stderr_callback = opts.stderr

    -- Setup options
    local system_opts = vim.deepcopy(opts)

    -- Capture stderr for progress if requested
    if stderr_callback then
      system_opts.stderr = function(_, data)
        if data then
          table.insert(error_data, data)
          stderr_callback(_, data)
        end
      end
    end

    -- Call vim.system with proper error handling
    vim.system(cmd, system_opts, function(obj)
      -- Success is 0 exit code
      local success = obj.code == 0

      if success then
        callback(Result.success({
          stdout = obj.stdout,
          stderr = obj.stderr,
          code = obj.code,
          signal = obj.signal,
          progress = progress_data,
        }))
      else
        callback(Result.failure({
          message = 'Command failed with exit code: ' .. obj.code,
          stdout = obj.stdout,
          stderr = obj.stderr,
          code = obj.code,
          signal = obj.signal,
          progress = progress_data,
        }))
      end
    end)
  end
end

-- Await a promise - execution is paused until promise resolves
function _G.await(promise)
  local co = coroutine.running()
  if not co then
    error('Cannot await outside of an async function')
  end

  promise(function(result)
    vim.schedule(function()
      local ok = coroutine.resume(co, result)
      if not ok then
        vim.notify(debug.traceback(co), vim.log.levels.ERROR)
      end
    end)
  end)

  local result = coroutine.yield()

  -- Propagate errors by throwing them
  if not result.success then
    error(result.error)
  end

  return result.value
end

-- Safely await a promise, returning a result instead of throwing
function _G.try_await(promise)
  local co = coroutine.running()
  if not co then
    error('Cannot await outside of an async function')
  end

  promise(function(result)
    vim.schedule(function()
      local ok = coroutine.resume(co, result)
      if not ok then
        vim.notify(debug.traceback(co), vim.log.levels.ERROR)
      end
    end)
  end)

  return coroutine.yield()
end

-- Create an async function that can use await
function _G.async(func)
  return function(...)
    local args = { ... }
    local co = coroutine.create(function()
      local status, result = pcall(function()
        return func(unpack(args))
      end)

      if not status then
        vim.schedule(function()
          vim.notify('Async error: ' .. tostring(result), vim.log.levels.ERROR)
        end)
      end

      return status and result or nil
    end)

    local function step(...)
      local ok, err = coroutine.resume(co, ...)
      if not ok then
        vim.schedule(function()
          vim.notify('Coroutine error: ' .. debug.traceback(co, err), vim.log.levels.ERROR)
        end)
      end
    end

    step()
  end
end
