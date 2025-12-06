local api = vim.api
local fn = vim.fn

local M = {}

local terminals = {}
local current_term_id = nil

local default_config = {
  size_presets = {
    small = { width = 0.5, height = 0.4 },
    medium = { width = 0.7, height = 0.6 },
    large = { width = 0.9, height = 0.8 },
    full = { width = 0.95, height = 0.95 },
  },
  default_size = 'medium',
  title = ' Terminal ',
  title_pos = 'center',
  show_statusline = false,
  auto_insert = true,
  auto_close = true,
}

local config = vim.deepcopy(default_config)

local term_id_counter = 0
local function gen_term_id()
  term_id_counter = term_id_counter + 1
  return term_id_counter
end

local function calc_win_config(size_preset)
  local size = config.size_presets[size_preset or config.default_size]

  local width = math.floor(vim.o.columns * size.width)
  local height = math.floor(vim.o.lines * size.height)
  local col = math.floor((vim.o.columns - width) / 2)
  local row = math.floor((vim.o.lines - height) * 0.4)

  return {
    relative = 'editor',
    width = width,
    height = height,
    col = col,
    row = row,
    style = 'minimal',
    zindex = 50,
    focusable = true,
  }
end

local function setup_keymaps(term)
  local opts = { buffer = term.bufnr, noremap = true, silent = true }

  vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', opts)
  vim.keymap.set('t', '<C-w>h', '<C-\\><C-n><C-w>h', opts)
  vim.keymap.set('t', '<C-w>j', '<C-\\><C-n><C-w>j', opts)
  vim.keymap.set('t', '<C-w>k', '<C-\\><C-n><C-w>k', opts)
  vim.keymap.set('t', '<C-w>l', '<C-\\><C-n><C-w>l', opts)
  vim.keymap.set('t', '<C-w>q', '<C-\\><C-n>:close<CR>', opts)

  vim.keymap.set('n', 'q', function()
    M.close(term.id)
  end, opts)

  local function resize(direction, amount)
    if not api.nvim_win_is_valid(term.winid) then
      return
    end
    local win_config = api.nvim_win_get_config(term.winid)

    if direction == 'width' then
      win_config.width = math.max(20, win_config.width + amount)
    elseif direction == 'height' then
      win_config.height = math.max(5, win_config.height + amount)
    end

    api.nvim_win_set_config(term.winid, win_config)
  end

  vim.keymap.set('n', '<C-Left>', function()
    resize('width', -5)
  end, opts)
  vim.keymap.set('n', '<C-Right>', function()
    resize('width', 5)
  end, opts)
  vim.keymap.set('n', '<C-Up>', function()
    resize('height', -2)
  end, opts)
  vim.keymap.set('n', '<C-Down>', function()
    resize('height', 2)
  end, opts)
end

function M.toggle(opts)
  opts = opts or {}

  if current_term_id then
    local term = terminals[current_term_id]
    if term and term.winid and api.nvim_win_is_valid(term.winid) then
      local cur_win = api.nvim_get_current_win()
      if cur_win == term.winid then
        M.close(current_term_id)
        return
      end
    end
  end

  M.open(opts)
end

function M.open(opts)
  opts = opts or {}
  local term_id = opts.term_id or current_term_id
  local term = term_id and terminals[term_id] ---@type table?

  if term and term.winid and api.nvim_win_is_valid(term.winid) then
    api.nvim_set_current_win(term.winid)
    if config.auto_insert then
      vim.cmd('startinsert!')
    end
    return term
  end
  local spawn_new = not term
  if spawn_new then
    term_id = gen_term_id()
    local cmd = opts.cmd or (fn.has('win32') == 1 and 'cmd.exe' or os.getenv('SHELL'))
    local cwd = opts.cwd or fn.getcwd()
    local name = opts.name or ('Term #' .. term_id)

    term = {
      id = term_id,
      bufnr = nil,
      winid = nil,
      name = name,
      cmd = cmd,
      cwd = cwd,
      size_preset = opts.size or config.default_size,
      job_id = nil,
      created_at = os.time(),
    }

    terminals[term_id] = term
  end
  if not term then
    return
  end

  local win_config = calc_win_config(term.size_preset)
  if spawn_new then
    term.bufnr = api.nvim_create_buf(false, true)
  else
    win_config.noautocmd = true
  end

  term.winid = api.nvim_open_win(term.bufnr, true, win_config)
  vim.bo[term.bufnr].bufhidden = 'hide'
  vim.bo[term.bufnr].filetype = 'floatterm'
  vim.bo[term.bufnr].buflisted = false

  if spawn_new then
    term.job_id = fn.jobstart(term.cmd, {
      term = true,
      cwd = term.cwd,
      on_exit = function(_, _)
        if term.winid and api.nvim_win_is_valid(term.winid) then
          if config.auto_close then
            api.nvim_win_close(term.winid, true)
          end
        end

        terminals[term.id] = nil
        if current_term_id == term.id then
          current_term_id = nil
        end
      end,
    })

    setup_keymaps(term)
  end

  if config.auto_insert then
    vim.cmd('startinsert!')
  end

  api.nvim_create_autocmd('WinClosed', {
    pattern = tostring(term.winid),
    once = true,
    callback = function()
      term.winid = nil
    end,
  })

  current_term_id = term.id
  return term
end

function M.close(term_id)
  local term = term_id and terminals[term_id] or terminals[current_term_id]
  if not term or not term.winid or not api.nvim_win_is_valid(term.winid) then
    return
  end

  api.nvim_win_close(term.winid, true)
  term.winid = nil
end

function M.send(cmd, term_id)
  local term = term_id and terminals[term_id] or terminals[current_term_id]
  if not term or not term.job_id then
    vim.notify('Terminal not found', vim.log.levels.WARN)
    return
  end

  api.nvim_chan_send(term.job_id, cmd .. '\n')
end

function M.exec(cmd, opts)
  opts = opts or {}
  local term = M.open(opts)
  vim.defer_fn(function()
    if term and term.job_id then
      M.send(cmd, term.id)
    end
  end, 100)
end

function M.list()
  return vim.tbl_values(terminals)
end

function M.select()
  local term_list = M.list()

  if #term_list == 0 then
    vim.notify('No terminals', vim.log.levels.INFO)
    return
  end

  local items = vim.tbl_map(function(t)
    local status = t.winid and api.nvim_win_is_valid(t.winid) and '[Open]' or '[Hidden]'
    return string.format('%d: %s %s', t.id, t.name, status)
  end, term_list)

  vim.ui.select(items, {
    prompt = 'Select terminal:',
  }, function(_, idx)
    if idx then
      M.open({ term_id = term_list[idx].id })
    end
  end)
end

function M.kill(term_id)
  local term = term_id and terminals[term_id] or terminals[current_term_id]
  if not term then
    return
  end

  if term.job_id then
    fn.jobstop(term.job_id)
  end

  if term.bufnr and api.nvim_buf_is_valid(term.bufnr) then
    api.nvim_buf_delete(term.bufnr, { force = true })
  end

  terminals[term.id] = nil
  if current_term_id == term.id then
    current_term_id = nil
  end
end

return M
