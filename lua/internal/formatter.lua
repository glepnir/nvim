local uv, api, lsp, fn = vim.loop, vim.api, vim.lsp, vim.fn
local fmt = {}

local function get_format_opt()
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

function fmt:format_file(err, data, buf_data)
  assert(not err, err)
  local new_content = buf_data.new_content
  if data then
    local lines = vim.split(data, '\n')
    if next(new_content) ~= nil and not new_content[#new_content]:find('\n') then
      new_content[#new_content] = new_content[#new_content] .. lines[1]
      table.remove(lines, 1)
    end

    for _, line in pairs(lines) do
      table.insert(new_content, line)
    end
    return
  end

  if next(new_content) == nil then
    return
  end

  if not api.nvim_buf_is_valid(buf_data.buffer) then
    return
  end

  local curr_changedtick = api.nvim_buf_get_changedtick(buf_data.buffer)

  if buf_data.initial_changedtick ~= curr_changedtick then
    return
  end

  if string.len(new_content[#new_content]) == 0 then
    table.remove(new_content, #new_content)
  end

  if not check_same(buf_data.contents, new_content) then
    local view = fn.winsaveview()
    api.nvim_buf_set_lines(buf_data.buffer, 0, -1, false, new_content)
    fn.winrestview(view)
    vim.cmd.write()
  end
  self[buf_data.buffer] = nil
end

function fmt:get_buf_contents(bufnr)
  local contents = api.nvim_buf_get_lines(bufnr, 0, -1, false)
  self[bufnr].contents = contents
  self[bufnr].contents_with_wrap = {}
  for i, text in pairs(contents) do
    self[bufnr].contents_with_wrap[i] = text .. '\n'
  end
end

function fmt:new_spawn(buf_data)
  local stdout = uv.new_pipe(false)
  local stderr = uv.new_pipe(false)
  local stdin = uv.new_pipe(false)

  local opt = buf_data.opt
  self.handle, self.pid = uv.spawn(opt.cmd, {
    args = opt.args,
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
      self:format_file(err, data, buf_data)
    end)
  )

  uv.read_start(stderr, function(err, _)
    assert(not err, err)
  end)

  if api.nvim_buf_get_option(buf_data.buffer, 'filetype') == 'lua' then
    uv.write(stdin, buf_data.contents_with_wrap)
  end

  uv.shutdown(stdin, function()
    safe_close(stdin)
  end)
end

function fmt:formatter()
  local opt = get_format_opt()
  if not opt then
    return
  end

  local curr_buf = api.nvim_get_current_buf()
  local curr_changedtick = api.nvim_buf_get_changedtick(curr_buf)
  -- this mean there already have a working progress
  if self[curr_buf] and self[curr_buf].initial_changedtick == curr_changedtick then
    return
  end

  self[curr_buf] = {}
  self[curr_buf].initial_changedtick = curr_changedtick
  self[curr_buf].buffer = curr_buf
  self[curr_buf].new_content = {}
  self:get_buf_contents(curr_buf)
  self[curr_buf].opt = opt
  fmt:new_spawn(self[curr_buf])
end

local mt = {
  __newindex = function(t, k, v)
    rawset(t, k, v)
  end,
}

fmt = setmetatable(fmt, mt)

local get_lsp_client = function()
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

  if fn.filereadable(dir .. '/' .. format_tool_confs[vim.bo.filetype]) == 1 then
    return true
  end

  return false
end

local group = api.nvim_create_augroup('My format with lsp and third tools', { clear = false })

local function remove_autocmd(bufnr, id)
  api.nvim_create_autocmd('BufDelete', {
    group = group,
    buffer = bufnr,
    callback = function(opt)
      pcall(api.nvim_del_autocmd, id)
      pcall(api.nvim_del_autocmd, opt.id)
    end,
    desc = 'clean the format event',
  })
end

function fmt:event(bufnr)
  local id = api.nvim_create_autocmd('BufWritePre', {
    group = group,
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
        lsp.buf.code_action({ context = { only = { 'source.organizeImports' } }, apply = true })
      end

      local root_dir = client.config.root_dir
      if root_dir and use_format_tool(root_dir) then
        self:formatter()
        return
      end

      lsp.buf.format({ async = true })
    end,
    desc = 'My format',
  })
  remove_autocmd(bufnr, id)
end

return fmt
