local api, QUICK, LOCAL, FORWARD, BACKWARD, mapset = vim.api, 1, 2, 1, 2, vim.keymap.set
local treesitter, fn = vim.treesitter, vim.fn

local state = {
  preview = {
    win = nil,
    enabled = false,
  },
  count = 0,
  match_ids = {},
}

local function create_preview_window(bufnr)
  local preview = state.preview
  local qf_win = api.nvim_get_current_win()
  local qf_width = api.nvim_win_get_width(qf_win)
  local qf_position = api.nvim_win_get_position(qf_win)

  local preview_height = math.floor(vim.o.lines * 0.6)
  local preview_row = qf_position[1] - preview_height - 3

  if preview_row < 0 then
    preview_row = 0
    preview_height = qf_position[1] - 1
  end

  local win_opts = {
    style = 'minimal',
    relative = 'editor',
    row = preview_row,
    col = qf_position[2],
    width = qf_width,
    height = preview_height,
    focusable = false,
  }

  preview.win = api.nvim_open_win(bufnr, false, win_opts)

  mapset('n', '<Esc>', function()
    if preview.win and api.nvim_win_is_valid(preview.win) then
      api.nvim_win_close(preview.win, true)
      preview.win = nil
    end
  end, { buffer = preview.buf })

  api.nvim_create_autocmd('WinClosed', {
    buffer = bufnr,
    once = true,
    callback = function()
      api.nvim_win_close(preview.win, true)
      state.count = 0
      state.preview.win = nil
      state.preview.enabled = false
    end,
  })
end

local function update_preview()
  local preview = state.preview
  if not preview.enabled then
    return
  end

  local win_id = api.nvim_get_current_win()
  local win_info = fn.getwininfo(win_id)[1]

  local is_loclist = win_info.loclist == 1

  local idx = fn.line('.')
  local list = is_loclist and fn.getloclist(0) or fn.getqflist()

  if idx > 0 and idx <= #list then
    local item = list[idx]
    if not item.bufnr then
      return
    end

    if not preview.win or not api.nvim_win_is_valid(preview.win) then
      create_preview_window(item.bufnr)
    end

    local ft = vim.filetype.match({ buf = item.bufnr })
    if ft then
      local lang = treesitter.language.get_lang(ft)
      local ok = pcall(treesitter.get_parser, item.bufnr, lang)
      if ok then
        vim.treesitter.start(item.bufnr, lang)
      end
    end

    if preview.win and api.nvim_win_is_valid(preview.win) then
      api.nvim_win_set_buf(preview.win, item.bufnr)
      api.nvim_win_set_cursor(preview.win, { item.lnum, item.col })
      api.nvim_win_call(preview.win, function()
        vim.cmd('normal! zz')
      end)
    end
  end
end

local function toggle_preview(buf)
  local preview = state.preview
  preview.enabled = not preview.enabled
  if preview.enabled then
    update_preview()
    api.nvim_create_autocmd('CursorMoved', {
      buffer = buf,
      callback = update_preview,
    })
  elseif preview.win and api.nvim_win_is_valid(preview.win) then
    api.nvim_win_close(preview.win, true)
    preview.win = nil
  end
end

local function setup_init(buf, is_quick)
  vim.opt_local.wrap = false
  vim.opt_local.number = false
  vim.opt_local.relativenumber = false
  vim.opt_local.signcolumn = 'no'

  local win = api.nvim_get_current_win()
  fn.clearmatches(win)

  fn.matchadd('qfFileName', '^▸ \\zs.*', 12, -1, { window = win })
  fn.matchadd('qfLineNr', '^\\s\\+\\d\\+:\\d\\+', 20, -1, { window = win })
  fn.matchadd('qfSeparator', '│', 15, -1, { window = win })
  fn.matchadd('qfText', '│ \\zs.*', 10, -1, { window = win })

  local move = function(dir)
    return function()
      api.nvim_buf_call(buf, function()
        pcall(
          vim.cmd,
          dir == FORWARD and (is_quick and 'cnext' or 'lnext') or (is_quick and 'cprev' or 'lprev')
        )
        update_preview()
      end)
    end
  end

  local preview = state.preview
  mapset('n', 'q', function()
    if preview.win and api.nvim_win_is_valid(preview.win) then
      api.nvim_win_close(preview.win, true)
      preview.win = nil
    end
    vim.cmd('cclose')
  end, { buffer = buf })

  mapset('n', '<C-n>', move(FORWARD), { buffer = buf })
  mapset('n', '<C-p>', move(BACKWARD), { buffer = buf })

  mapset('n', 'p', function()
    toggle_preview(buf)
  end, { buffer = buf })
end

local function update_title()
  local width = 15
  local bar = ''

  if not state.done then
    local anim_pos = state.count % width
    for i = 1, width do
      bar = bar .. (i == anim_pos and '●' or '○')
    end
  else
    bar = string.rep('●', width)
  end

  vim.wo[state.win].stl =
    string.format(' %s [%s] %d matches', state.done and 'Done' or 'Searching', bar, state.count)
  api.nvim__redraw({
    win = state.win,
    buf = state.buf,
    statusline = true,
  })
end

function _G.compact_quickfix_format(info)
  local lines = {}
  local list = info.quickfix == 1 and vim.fn.getqflist() or vim.fn.getloclist(info.winid)
  local last_bufnr = nil

  for i = info.start_idx, info.end_idx do
    local item = list[i]
    if item and item.valid == 1 and item.lnum > 0 and item.text ~= '' then
      local filename = item.bufnr > 0 and vim.fn.bufname(item.bufnr) or ''
      local text = item.text or ''

      if item.bufnr ~= last_bufnr then
        table.insert(lines, string.format('▸ %s', filename))
        last_bufnr = item.bufnr
      end

      table.insert(lines, string.format('  %4d:%-3d │ %s', item.lnum, item.col, text))
    end
  end
  return lines
end

local grep = async(function(t, ...)
  local args = { ... }
  local grepprg = vim.o.grepprg
  local cmd = vim.split(grepprg, '%s+', { trimempty = true })
  local qf_fn = t == QUICK and function(...)
    fn.setqflist(...)
  end or function(...)
    fn.setloclist(0, ...)
  end

  for _, arg in ipairs(args) do
    table.insert(cmd, arg)
  end
  table.insert(cmd, '--fixed-strings')

  local opened = false
  local id = nil
  local batch_size = 200
  local chunk = {}
  local seen_files = {}
  local result = try_await(asystem(cmd, {
    text = true,
    stdout = function(err, data)
      assert(not err)
      state.done = not data
      local process = {}
      if data then
        local lines = vim.split(data, '\n', { trimempty = true })
        if #lines > 0 then
          for _, line in ipairs(lines) do
            -- parse format: filename:lnum:col:text
            local filename, lnum, col, text = line:match('^([^:]+):(%d+):(%d+):(.*)$')
            if filename and lnum and col and text then
              -- check is new file
              if not seen_files[filename] then
                -- insert header for it
                table.insert(chunk, string.format('%s:0:0:', filename))
                seen_files[filename] = true
              end
            end
            table.insert(chunk, line)
          end
        end
      end

      if #chunk >= batch_size then
        process = { unpack(chunk, 1, batch_size) }
        chunk = { unpack(chunk, batch_size + 1, #chunk) }
      end

      vim.schedule(function()
        if #process > 0 or data ~= nil then
          qf_fn({}, 'a', {
            lines = not data and chunk or process,
            id = id,
            efm = vim.o.errorformat,
            quickfixtextfunc = 'v:lua.compact_quickfix_format',
            title = 'Grep',
          })

          if not opened then
            vim.cmd(t == QUICK and 'copen' or 'lopen')
            local buf = api.nvim_get_current_buf()
            state.win = api.nvim_get_current_win()
            setup_init(buf, t == QUICK)
            opened = true
          end

          state.count = state.count + (not data and #chunk or #process)
          update_title()
        end
      end)
    end,
  }))

  if result.error then
    return vim.notify('Grep failed: ' .. tostring(result.error.message or ''), vim.log.levels.ERROR)
  end
end)

api.nvim_create_user_command('Grep', function(opts)
  grep(LOCAL, opts.args)
end, { nargs = '+', complete = 'file_in_path', desc = 'Search using localtion list' })

api.nvim_create_user_command('GREP', function(opts)
  grep(QUICK, opts.args)
end, { nargs = '+', complete = 'file_in_path', desc = 'Search using quickfix list' })

api.nvim_create_autocmd('CmdlineEnter', {
  pattern = ':',
  callback = function()
    vim.cmd(
      [[cnoreabbrev <expr> grep (getcmdtype() ==# ':' && getcmdline() ==# 'grep') ? 'Grep' : 'grep']]
    )
  end,
})
