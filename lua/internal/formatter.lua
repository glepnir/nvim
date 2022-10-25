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

local temp_data = {}

function fmt:format_file(err, data)
  assert(not err, err)
  if data and type(data) == 'string' then
    local lines = vim.split(data, '\n')
    if next(temp_data) ~= nil and not temp_data[#temp_data]:find('\n') then
      temp_data[#temp_data] = temp_data[#temp_data] .. lines[1]
      table.remove(lines, 1)
    end

    for _, line in pairs(lines) do
      table.insert(temp_data, line)
    end
    return
  end

  if next(temp_data) == nil then
    return
  end

  if string.len(temp_data[#temp_data]) == 0 then
    table.remove(temp_data, #temp_data)
  end

  local current_buf = api.nvim_get_current_buf()
  if not self[current_buf] then
    self[current_buf] = {}
    self[current_buf].old_lines = {}
  end

  if not check_same(self[current_buf].old_lines, temp_data) then
    api.nvim_buf_set_lines(current_buf, 0, -1, false, temp_data)
    self[current_buf].old_lines = temp_data
  end

  if not self[current_buf].au_id then
    self[current_buf].au_id = api.nvim_create_autocmd('BufDelete', {
      buffer = current_buf,
      callback = function()
        api.nvim_del_augroup_by_id(self[current_buf].au_id)
        rawset(self, current_buf, nil)
      end,
      desc = 'Format with tools',
    })
  end

  temp_data = {}
end

function fmt:get_buf_contents()
  local contents = api.nvim_buf_get_lines(0, 0, -1, false)
  for i, text in pairs(contents) do
    contents[i] = text .. '\n'
  end
  local buf = api.nvim_get_current_buf()
  if not self[buf] then
    self[buf] = {}
  end
  self[buf].old_lines = contents
  return contents
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

  if opts.contents then
    uv.write(stdin, opts.contents)
  end

  uv.shutdown(stdin, function()
    safe_close(stdin)
  end)
end

function fmt:formatter()
  local opts = get_format_opts()
  if not opts then
    return
  end

  if vim.bo.filetype == 'lua' then
    opts.contents = self:get_buf_contents()
  end
  fmt:new_spawn(opts)
end

local mt = {
  __newindex = function(t, k, v)
    rawset(t, k, v)
  end,
}

fmt = setmetatable(fmt, mt)

local get_lsp_client = function()
  local lsp = vim.lsp
  local current_buf = api.nvim_get_current_buf()
  local clients = lsp.get_active_clients({ buffer = current_buf })
  if next(clients) == nil then
    return nil
  end

  for _, client in pairs(clients) do
    local fts = client.config.filetypes
    if
      client.server_capabilities.documentFormattingProvider
      and vim.tbl_contains(fts, vim.bo.filetype)
    then
      return client
    end
  end
end

local format_tool_confs = {
  ['lua'] = '.stylua.toml',
}

local use_format_tool = function(dir)
  if not format_tool_confs[vim.bo.filetype] then
    return false
  end

  if vim.fn.filereadable(dir .. '/' .. format_tool_confs[vim.bo.filetype]) then
    return true
  end

  return false
end

function fmt:event(bufnr)
  api.nvim_create_autocmd('BufWritePre', {
    group = api.nvim_create_augroup('My format with lsp and third tools', { clear = true }),
    buffer = bufnr,
    callback = function(opt)
      local fname = opt.match
      if vim.bo.filetype == 'lua' and fname:find('%pspec') then
        return
      end

      if fname:find('neovim/*') then
        return
      end

      local client = get_lsp_client()
      if not client then
        return
      end

      if vim.bo.filetype == 'go' then
        vim.lsp.buf.code_action({ context = { only = { 'source.organizeImports' } }, apply = true })
      end

      local root_dir = client.config.root_dir
      if root_dir and use_format_tool(root_dir) then
        self:formatter()
        return
      end

      vim.lsp.buf.format({ async = true })
    end,
    desc = 'My format',
  })
end

return fmt
