local api = vim.api
local run = require('run')

local COMPILE_PREFIX = 'COMPILE_COMMAND='

local function read_env_lines()
  local env_file = vim.fs.joinpath(run.find_root(), '.env')

  local stat = vim.uv.fs_stat(env_file)
  if not stat or stat.type ~= 'file' or stat.size == 0 then
    return env_file, nil
  end

  local fd = vim.uv.fs_open(env_file, 'r', 438)
  if not fd then
    return env_file, nil
  end

  local data = vim.uv.fs_read(fd, stat.size, 0)
  vim.uv.fs_close(fd)
  if not data then
    return env_file, nil
  end

  return env_file, vim.split((data:gsub('\r\n', '\n')), '\n')
end

local function unquote(s)
  local q = s:sub(1, 1)
  if #s >= 2 and (q == '"' or q == "'") and s:sub(-1) == q then
    return s:sub(2, -2)
  end
  return s
end

local function read_compile_command()
  local _, lines = read_env_lines()
  if not lines then
    return nil
  end
  for _, line in ipairs(lines) do
    -- Match on the '=' too: plain 'COMPILE_COMMAND' also matched
    -- COMPILE_COMMAND_EXTRA=... and returned a mangled sub().
    if vim.startswith(line, COMPILE_PREFIX) then
      local value = unquote(vim.trim(line:sub(#COMPILE_PREFIX + 1)))
      if value ~= '' then
        return value
      end
    end
  end
  return nil
end

--- Write (or update) COMPILE_COMMAND in the project-root .env file.
--- Preserves any other lines already present. Returns the path on success.
local function write_compile_command(cmd)
  cmd = vim.trim(cmd)
  local env_file, existing = read_env_lines()

  local lines = {}
  local replaced = false

  for _, line in ipairs(existing or {}) do
    if vim.startswith(line, COMPILE_PREFIX) then
      if not replaced then
        table.insert(lines, COMPILE_PREFIX .. cmd)
        replaced = true
      end -- later duplicates are dropped rather than multiplied
    else
      table.insert(lines, line)
    end
  end

  if not replaced then
    while #lines > 0 and vim.trim(lines[#lines]) == '' do
      table.remove(lines)
    end
    table.insert(lines, COMPILE_PREFIX .. cmd)
  end

  local fd = vim.uv.fs_open(env_file, 'w', tonumber('644', 8))
  if not fd then
    vim.notify('Failed to write ' .. env_file, vim.log.levels.ERROR)
    return nil
  end
  local written = vim.uv.fs_write(fd, table.concat(lines, '\n') .. '\n', 0)
  vim.uv.fs_close(fd)
  if not written then
    vim.notify('Failed to write ' .. env_file, vim.log.levels.ERROR)
    return nil
  end
  vim.notify('Saved COMPILE_COMMAND -> ' .. env_file, vim.log.levels.INFO)
  return env_file
end

api.nvim_create_user_command('Compile', function(args)
  run.stop()
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
  cmd, silent = run.strip_silent(cmd)
  run.run(cmd, api.nvim_buf_get_name(0), { silent = silent })
  -- NOTE: no `complete = 'file'`. File-type completion makes Vim treat the
  -- args as filenames and expand `%`/`#` (cmdline-special) *before* we see
  -- them, which would turn a typed `%s` into the current filename + 's'.
end, { nargs = '?' })

api.nvim_create_user_command('Recompile', function()
  run.rerun()
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
    local stripped, silent = run.strip_silent(cmd)
    run.remember(stripped, silent)
  end
  -- No `complete = 'file'` here either: we want a literal `%s` placeholder
  -- written to .env, not Vim's current-file expansion.
end, { nargs = '?' })

return {
  custom = function(opts)
    -- Same as :Compile — without this, a still-running job kept streaming into
    -- the list this call is about to create.
    run.stop()
    run.run(opts.cmd, opts.fname, {
      silent = opts.silent,
      ondone = opts.ondone,
    })
  end,
  stop = run.stop,
}
