-- clangd.lua — generate a project-root .clangd config.
-- Standalone: no dependency on the compile module.

local api = vim.api

--- Find the project root by walking up from the current buffer.
--- Falls back to the current working directory.
local function find_root()
  local root = vim.fs.root(0, {
    '.git',
    '.svn',
    '.clangd',
    'compile_commands.json',
    'compile_flags.txt',
    'CMakeLists.txt',
    'Makefile',
  })
  return root or vim.uv.cwd()
end

-- Resolve a user token into a real -std value.
-- Presets: modern -> c++23, latest -> c++26, legacy -> c++17, old -> c++11.
-- Also accepts explicit forms: c++20, gnu++23, c++2b, or a bare year (23).
local function resolve_std(token)
  token = token:lower()
  local presets = { modern = 'c++23', latest = 'c++26', legacy = 'c++17', old = 'c++11' }
  if presets[token] then
    return presets[token]
  end
  if token:match('^c%+%+%w+$') or token:match('^gnu%+%+%w+$') then
    return token
  end
  if token:match('^%d+$') then
    return 'c++' .. token
  end
  return nil
end

local STD_YEAR = {
  ['0x'] = 11,
  ['11'] = 11,
  ['1y'] = 14,
  ['14'] = 14,
  ['1z'] = 17,
  ['17'] = 17,
  ['2a'] = 20,
  ['20'] = 20,
  ['2b'] = 23,
  ['23'] = 23,
  ['2c'] = 26,
  ['26'] = 26,
}
local function std_year(std)
  local v = std:match('%+%+(%w+)$')
  return v and (STD_YEAR[v] or tonumber(v)) or nil
end

-- Resolve the C++ compiler to probe. Prefer the one actually used in .env's
-- COMPILE_COMMAND (soft dependency: silently skipped when there is no .env),
-- so the result matches your real build. Returns a command name/path or nil.
local function compiler_from_env()
  local env = vim.fs.joinpath(find_root(), '.env')
  local st = vim.uv.fs_stat(env)
  if not st or st.size == 0 then
    return nil
  end
  local fd = vim.uv.fs_open(env, 'r', 438)
  if not fd then
    return nil
  end
  local data = vim.uv.fs_read(fd, st.size, 0) or ''
  vim.uv.fs_close(fd)
  for _, line in ipairs(vim.split(data, '\n')) do
    if vim.startswith(line, 'COMPILE_COMMAND') then
      return vim.trim(line:sub(17)):match('^(%S+)')
    end
  end
  return nil
end

-- Ask the compiler where it lives, via `cc -print-search-dirs`. The `install:`
-- line is exactly what --gcc-install-dir wants. Kept only if it is a real GCC
-- install (a `gcc` path component) -- this rejects Apple Clang / clang, whose
-- install dir lives under `clang`. Returns the dir, or nil.
local function gcc_install_dir(cc)
  if not cc or cc == '' then
    return nil
  end
  local exe = vim.fn.exepath(cc)
  if exe == '' then
    return nil
  end
  local ok, res = pcall(function()
    return vim.system({ exe, '-print-search-dirs' }, { text = true }):wait(3000)
  end)
  if not ok or not res or res.code ~= 0 or not res.stdout then
    return nil
  end
  local dir = res.stdout:match('install:%s*([^\r\n]+)')
  if not dir then
    return nil
  end
  dir = vim.trim(dir)
  dir = (dir:gsub('[/\\]+$', '')) -- strip trailing slash
  if not dir:match('[/\\]gcc[/\\]') then
    return nil -- clang resource dir, not a GCC install
  end
  local st = vim.uv.fs_stat(dir)
  return (st and st.type == 'directory') and dir or nil
end

-- Compiler names to try when .env yields nothing, ordered per platform. On
-- macOS bare `g++` is Apple Clang and gets rejected by gcc_install_dir, so
-- Homebrew-versioned names come first.
local function candidate_compilers(sys)
  if sys == 'Darwin' then
    return { 'g++-15', 'g++-14', 'g++-13', 'g++' }
  elseif sys == 'Windows_NT' then
    return { 'g++', 'c++' }
  end
  return { 'g++', 'g++-15', 'g++-14', 'c++' }
end

-- Best GCC install dir for --gcc-install-dir, or nil. Probes the real compiler
-- (.env first, then platform candidates) instead of guessing fixed paths.
local function detect_gcc_dir()
  local from_env = gcc_install_dir(compiler_from_env())
  if from_env then
    return from_env
  end
  for _, cc in ipairs(candidate_compilers(vim.uv.os_uname().sysname)) do
    local dir = gcc_install_dir(cc)
    if dir then
      return dir
    end
  end
  return nil
end

-- Commented hint for getting modern stdlib headers (<print>, <format>,
-- <ranges>) when clangd's bundled clang can't find them. Probes the real
-- compiler for a GCC install dir; otherwise falls back to per-OS guidance.
-- Never emits a fabricated path. Returns a list of comment lines (may be empty).
local function libstdcxx_hint()
  local dir = detect_gcc_dir()
  if dir then
    return {
      '  # GCC libstdc++ detected. If clangd reports <print>/<format>/<ranges>',
      '  # missing, its bundled clang is on an older libstdc++. Add to the Add',
      '  # list below (needs Clang 16+):',
      '  #   --gcc-install-dir=' .. dir,
    }
  end

  local sys = vim.uv.os_uname().sysname
  if sys == 'Darwin' then
    return {
      '  # No GCC found; macOS default is Apple Clang + libc++. Missing',
      '  # <print>/<format>/<ranges> usually means Xcode / Command Line Tools is',
      '  # too old (a flag cannot add them - update Xcode). If clangd picks the',
      '  # wrong SDK, add to Add below:',
      '  #   -isysroot <path from: xcrun --show-sdk-path>',
    }
  elseif sys == 'Windows_NT' then
    return {} -- likely MSVC: driven by INCLUDE / vcvars; no portable flag.
  end
  return {
    '  # No GCC auto-detected. If <print>/<format>/<ranges> are reported missing,',
    '  # point clangd at a newer GCC -- its dir is the `install:` line of',
    '  #   g++ -print-search-dirs   -- then add to Add below (needs Clang 16+):',
    '  #   --gcc-install-dir=<that dir>',
  }
end

-- Write a fresh .clangd (overwrite) with a flow-style Add list. The core
-- -std/-W flags are written on every OS; for C++20+ a platform-aware, commented
-- libstdc++/libc++ hint precedes Add (see libstdcxx_hint).
local function write_clangd(std, path)
  local flags = { '-std=' .. std, '-Wall', '-Wextra' }
  local lines = { 'CompileFlags:' }
  if (std_year(std) or 0) >= 20 then
    vim.list_extend(lines, libstdcxx_hint())
  end
  table.insert(lines, '  Add: [' .. table.concat(flags, ', ') .. ']')

  local fd = vim.uv.fs_open(path, 'w', tonumber('644', 8))
  if not fd then
    vim.notify('Failed to write ' .. path, vim.log.levels.ERROR)
    return nil
  end
  vim.uv.fs_write(fd, table.concat(lines, '\n') .. '\n', 0)
  vim.uv.fs_close(fd)
  return path
end

-- Best-effort: restart attached clangd clients so the new config is read.
-- Falls back silently to the :LspRestart hint in the notification.
local function restart_clangd()
  local ok, clients = pcall(function()
    return vim.lsp.get_clients({ name = 'clangd' })
  end)
  if ok and clients then
    for _, client in ipairs(clients) do
      pcall(function()
        client:stop()
      end)
    end
  end
end

local function clangd_set(std)
  local path = vim.fs.joinpath(find_root(), '.clangd')
  if vim.uv.fs_stat(path) then
    local prompt = ('.clangd already exists at\n%s\nOverwrite?'):format(path)
    if vim.fn.confirm(prompt, '&Yes\n&No', 2) ~= 1 then
      return
    end
  end
  if write_clangd(std, path) then
    restart_clangd()
    vim.notify(
      ('Wrote %s  (-std=%s)\nReopen the file (or :LspRestart) to apply.'):format(path, std),
      vim.log.levels.INFO
    )
  end
end

-- Create a .clangd in the project root.
-- Usage: `:ClangdSet modern`   -> -std=c++23
--        `:ClangdSet legacy`   -> -std=c++17
--        `:ClangdSet c++20`    (explicit; also c++2b / gnu++23 / bare year 23)
--        `:ClangdSet`          (pick modern vs legacy from a menu)
api.nvim_create_user_command('ClangdSet', function(args)
  local token = vim.trim(args.args)
  if token ~= '' then
    local std = resolve_std(token)
    if not std then
      vim.notify('Unknown C++ standard: ' .. token, vim.log.levels.ERROR)
      return
    end
    clangd_set(std)
  else
    vim.ui.select({ 'modern  (c++23)', 'legacy  (c++17)' }, {
      prompt = 'C++ standard for .clangd:',
    }, function(choice)
      if not choice then
        return
      end
      clangd_set(choice:find('23') and 'c++23' or 'c++17')
    end)
  end
end, {
  nargs = '?',
  complete = function()
    return { 'modern', 'legacy', 'latest', 'c++17', 'c++20', 'c++23', 'c++2b', 'c++26' }
  end,
})

--- Implements the off-spec textDocument/switchSourceHeader method.
--- @param buf integer
local function switch_source_header(client, buf)
  client:request(
    'textDocument/switchSourceHeader',
    vim.lsp.util.make_text_document_params(buf),
    function(err, result)
      if err then
        vim.notify(err.message, vim.log.levels.ERROR)
        return
      end
      if not result then
        vim.notify('Corresponding file could not be determined', vim.log.levels.WARN)
        return
      end
      vim.cmd.edit(vim.uri_to_fname(result))
    end
  )
end

return {
  cmd = {
    -- 'clangd',
    vim.uv.os_uname().sysname:match('Darwin') and '/opt/homebrew/opt/llvm/bin/clangd' or 'clangd',
  },
  filetypes = { 'c', 'cpp', 'objc', 'objcpp', 'cuda', 'proto' },
  root_markers = {
    '.clangd',
    '.clang-tidy',
    '.clang-format',
    'compile_commands.json',
    'compile_flags.txt',
    'configure.ac', -- GNU Autotools.
  },
  get_language_id = function(_, ftype)
    local t = { objc = 'objective-c', objcpp = 'objective-cpp', cuda = 'cuda-cpp' }
    return t[ftype] or ftype
  end,
  reuse_client = function(client, config)
    return client.name == config.name
  end,
  capabilities = {
    textDocument = {
      completion = {
        editsNearCursor = true,
        completionItem = {
          snippetSupport = false,
        },
      },
    },
    -- Off-spec, but clangd and vim.lsp support UTF-8, which is more efficient.
    offsetEncoding = { 'utf-8', 'utf-16' },
  },
  on_init = function(client, init_result)
    if init_result.offsetEncoding then
      client.offset_encoding = init_result.offsetEncoding
    end
  end,

  -- Assumes at most one clangd client is attached to a buffer.
  on_attach = function(client, buf)
    vim.api.nvim_buf_create_user_command(buf, 'ClangdSwitchSourceHeader', function()
      switch_source_header(client, buf)
    end, {
      bar = true,
      desc = 'clangd: Switch Between Source and Header File',
    })
    vim.keymap.set('n', 'grs', '<Cmd>ClangdSwitchSourceHeader<CR>', {
      buffer = buf,
      desc = 'clangd: Switch Between Source and Header File',
    })

    vim.api.nvim_create_autocmd('LspDetach', {
      group = vim.api.nvim_create_augroup('conf_lsp_attach_detach', { clear = false }),
      buffer = buf,
      callback = function(args)
        if args.data.client_id == client.id then
          vim.keymap.del('n', 'grs', { buffer = buf })
          vim.api.nvim_buf_del_user_command(buf, 'ClangdSwitchSourceHeader')
          return true -- Delete this autocmd.
        end
      end,
    })
  end,
} --[[@as vim.lsp.Config]]
