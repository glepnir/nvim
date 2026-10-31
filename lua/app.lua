local api = vim.api
local M = {}

local dirs = {
  '/Applications',
  '/Applications/Utilities',
  '/System/Applications',
  '/System/Applications/Utilities',
  vim.fs.joinpath(vim.env.HOME, 'Applications'),
}

local cache
local ns = api.nvim_create_namespace('apps_picker')

local function collect()
  if cache then
    return cache
  end
  local seen, list = {}, {}
  for _, dir in ipairs(dirs) do
    if vim.uv.fs_stat(dir) then
      for name, t in vim.fs.dir(dir) do
        if name:sub(-4) == '.app' and (t == 'directory' or t == 'link') then
          local label = name:sub(1, -5)
          if not seen[label] then
            seen[label] = true
            list[#list + 1] = { name = label, path = vim.fs.joinpath(dir, name) }
          end
        end
      end
    end
  end
  table.sort(list, function(a, b)
    return a.name:lower() < b.name:lower()
  end)
  cache = list
  return list
end

function M.open(opts)
  if opts and opts.refresh then
    cache = nil
  end
  local apps = collect()
  local items, idx = apps, 1

  local width = math.min(60, math.floor(vim.o.columns * 0.6))
  local height = math.min(15, math.floor(vim.o.lines * 0.5))
  local row = math.floor((vim.o.lines - height - 3) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local pbuf = api.nvim_create_buf(false, true)
  local lbuf = api.nvim_create_buf(false, true)
  vim.bo[pbuf].bufhidden = 'wipe'
  vim.bo[lbuf].bufhidden = 'wipe'
  vim.bo[pbuf].complete = ''

  local lwin = api.nvim_open_win(lbuf, false, {
    relative = 'editor',
    row = row + 3,
    col = col,
    width = width,
    height = height,
    style = 'minimal',
    border = 'rounded',
    focusable = false,
  })
  local pwin = api.nvim_open_win(pbuf, true, {
    relative = 'editor',
    row = row,
    col = col,
    width = width,
    height = 1,
    style = 'minimal',
    border = 'rounded',
    title = ' Apps ',
    title_pos = 'center',
  })
  vim.wo[lwin].cursorline = true

  local closed = false
  local function close()
    if closed then
      return
    end
    closed = true
    vim.cmd.stopinsert()
    for _, w in ipairs({ pwin, lwin }) do
      if api.nvim_win_is_valid(w) then
        api.nvim_win_close(w, true)
      end
    end
  end

  local function render()
    local q = api.nvim_buf_get_lines(pbuf, 0, 1, false)[1] or ''
    local pos
    if q == '' then
      items = apps
    else
      local r = vim.fn.matchfuzzypos(apps, q, { key = 'name' })
      items, pos = r[1], r[2]
    end

    local lines = {}
    for i, it in ipairs(items) do
      lines[i] = ' ' .. it.name
    end
    if #lines == 0 then
      lines = { ' No Match' }
    end
    api.nvim_buf_set_lines(lbuf, 0, -1, false, lines)
    api.nvim_buf_clear_namespace(lbuf, ns, 0, -1)

    if pos then
      for i, p in ipairs(pos) do
        local name = items[i].name
        for _, c in ipairs(p) do
          local s = vim.str_byteindex(name, 'utf-32', c, false) + 1
          local e = vim.str_byteindex(name, 'utf-32', c + 1, false) + 1
          api.nvim_buf_set_extmark(lbuf, ns, i - 1, s, { end_col = e, hl_group = 'Special' })
        end
      end
    end

    idx = 1
    api.nvim_win_set_cursor(lwin, { 1, 0 })
  end

  local function move(d)
    if #items == 0 then
      return
    end
    idx = (idx - 1 + d) % #items + 1
    api.nvim_win_set_cursor(lwin, { idx, 0 })
  end

  local function confirm()
    local it = items[idx]
    close()
    if not it then
      return
    end
    vim.system({ 'open', it.path }, {}, function(p)
      if p.code ~= 0 then
        vim.schedule(function()
          vim.notify('Open Failed: ' .. it.name, vim.log.levels.ERROR)
        end)
      end
    end)
  end

  local map = function(lhs, fn)
    vim.keymap.set('i', lhs, fn, { buffer = pbuf, nowait = true })
  end
  map('<CR>', confirm)
  map('<Esc>', close)
  map('<C-c>', close)
  map('<C-n>', function()
    move(1)
  end)
  map('<Down>', function()
    move(1)
  end)
  map('<C-p>', function()
    move(-1)
  end)
  map('<Up>', function()
    move(-1)
  end)

  api.nvim_create_autocmd('TextChangedI', { buffer = pbuf, callback = render })
  api.nvim_create_autocmd('WinLeave', {
    buffer = pbuf,
    once = true,
    callback = function()
      vim.schedule(close)
    end,
  })

  render()
  vim.cmd.startinsert()
end

return M
