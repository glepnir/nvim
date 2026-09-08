local api, QUICK, LOCAL, FORWARD, BACKWARD, mapset = vim.api, 1, 2, 1, 2, vim.keymap.set
local treesitter, fn = vim.treesitter, vim.fn

local async = vim.async

local state = {
  preview = {
    win = nil,
    enabled = false,
    autocmd = nil,
  },
  count = 0,
  done = false,
  win = nil,
  buf = nil,
}

--- Close the preview float and leave preview mode.
local function close_preview()
  local preview = state.preview
  preview.enabled = false
  if preview.autocmd then
    pcall(api.nvim_del_autocmd, preview.autocmd)
    preview.autocmd = nil
  end
  if preview.win and api.nvim_win_is_valid(preview.win) then
    pcall(api.nvim_win_close, preview.win, true)
  end
  preview.win = nil
end

local function create_preview_window(bufnr)
  local preview = state.preview
  local qf_win = api.nvim_get_current_win()
  local qf_width = api.nvim_win_get_width(qf_win)
  local qf_position = api.nvim_win_get_position(qf_win)

  local preview_height = math.floor(vim.o.lines * 0.6)
  local preview_row = qf_position[1] - preview_height - 3

  if preview_row < 0 then
    preview_row = 0
    preview_height = math.max(qf_position[1] - 1, 1)
  end

  preview.win = api.nvim_open_win(bufnr, false, {
    style = 'minimal',
    relative = 'editor',
    row = preview_row,
    col = qf_position[2],
    width = qf_width,
    height = preview_height,
    focusable = false,
  })

  -- Clean up when the preview window itself gets closed by any means.
  api.nvim_create_autocmd('WinClosed', {
    pattern = tostring(preview.win),
    once = true,
    callback = close_preview,
  })
end

local function update_preview()
  local preview = state.preview
  if not preview.enabled then
    return
  end

  local win_info = fn.getwininfo(api.nvim_get_current_win())[1]
  if not win_info then
    return
  end
  local is_loclist = win_info.loclist == 1

  local idx = fn.line('.')
  local list = is_loclist and fn.getloclist(0) or fn.getqflist()
  local item = list[idx]
  -- NOTE: bufnr == 0 is truthy in Lua, must compare explicitly
  if not item or not item.bufnr or item.bufnr == 0 then
    return
  end

  if not preview.win or not api.nvim_win_is_valid(preview.win) then
    create_preview_window(item.bufnr)
  end
  if not (preview.win and api.nvim_win_is_valid(preview.win)) then
    return
  end

  api.nvim_win_set_buf(preview.win, item.bufnr)

  local ft = vim.filetype.match({ buf = item.bufnr })
  if ft then
    local lang = treesitter.language.get_lang(ft)
    if lang and pcall(treesitter.get_parser, item.bufnr, lang) then
      treesitter.start(item.bufnr, lang)
    end
  end

  -- Header rows use lnum == 0; win_set_cursor wants 1-based lnum, 0-based col.
  local lnum = math.max(item.lnum or 1, 1)
  local col = math.max((item.col or 1) - 1, 0)
  pcall(api.nvim_win_set_cursor, preview.win, { lnum, col })
  api.nvim_win_call(preview.win, function()
    vim.cmd('normal! zz')
  end)
end

local function toggle_preview(buf)
  local preview = state.preview
  if preview.enabled then
    close_preview()
    return
  end
  preview.enabled = true
  update_preview()
  preview.autocmd = api.nvim_create_autocmd('CursorMoved', {
    buffer = buf,
    callback = update_preview,
  })
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

  mapset('n', 'q', function()
    close_preview()
    vim.cmd(is_quick and 'cclose' or 'lclose')
  end, { buffer = buf })

  -- was { buffer = preview.buf } with a nil buf, which created a GLOBAL <Esc> map
  mapset('n', '<Esc>', close_preview, { buffer = buf })

  mapset('n', '<C-n>', move(FORWARD), { buffer = buf })
  mapset('n', '<C-p>', move(BACKWARD), { buffer = buf })

  mapset('n', 'p', function()
    toggle_preview(buf)
  end, { buffer = buf })
end

local function update_title()
  if not (state.win and api.nvim_win_is_valid(state.win)) then
    return
  end

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
  api.nvim__redraw({ win = state.win, statusline = true })
end

--- Stateless quickfixtextfunc: exactly ONE output line per item in
--- [start_idx, end_idx]. Header pseudo entries (lnum == 0) render as the
--- "▸ file" row themselves, so partial-range calls (which happen on every
--- appended batch) can never shift or duplicate lines.
local function qf_text(info)
  local items
  if info.quickfix == 1 then
    items = fn.getqflist({ id = info.id, items = 0 }).items
  else
    items = fn.getloclist(info.winid, { id = info.id, items = 0 }).items
  end

  local lines = {}
  for i = info.start_idx, info.end_idx do
    local item = items[i]
    if not item then
      lines[#lines + 1] = ''
    elseif (item.lnum or 0) == 0 then
      local name = item.bufnr and item.bufnr > 0 and fn.bufname(item.bufnr) or ''
      lines[#lines + 1] = string.format('▸ %s', name)
    else
      lines[#lines + 1] =
        string.format('  %4d:%-3d │ %s', item.lnum, item.col or 0, item.text or '')
    end
  end
  return lines
end

local function grep(t, ...)
  local args = { ... }
  if #args == 0 then
    return
  end

  -- Reset per-run UI state so a second :Grep does not inherit stale counters.
  state.count = 0
  state.done = false

  async.run(function()
    -- Build the command. Expand a '$*' placeholder in 'grepprg' if present,
    -- otherwise append the arguments at the end.
    local cmd = {}
    local expanded = false
    for _, part in ipairs(vim.split(vim.o.grepprg, '%s+', { trimempty = true })) do
      if part == '$*' then
        expanded = true
        table.insert(cmd, '--fixed-strings')
        vim.list_extend(cmd, args)
      else
        table.insert(cmd, part)
      end
    end
    if not expanded then
      table.insert(cmd, '--fixed-strings')
      vim.list_extend(cmd, args)
    end

    local is_quick = t == QUICK
    -- Location lists are per-window: remember whose list we own, otherwise
    -- appends go to whatever window happens to be focused later.
    local owner = api.nvim_get_current_win()
    local qf_fn = is_quick and function(...)
      fn.setqflist(...)
    end or function(...)
      fn.setloclist(owner, ...)
    end

    local opened = false
    local id = nil
    local batch_size = 200
    local chunk = {}
    local pending = '' -- carries an incomplete trailing line between stdout chunks
    local seen_files = {}
    local total = 0 -- real matches parsed so far
    local title = 'Grep ' .. table.concat(args, ' ')

    local function parse_line(line)
      -- grep/rg --vimgrep format: filename:lnum:col:text (col optional)
      local filename = line:match('^(.-):%d+:%d+:') or line:match('^(.-):%d+:')
      if filename then
        total = total + 1
        if not seen_files[filename] then
          seen_files[filename] = true
          -- pseudo entry (lnum == 0) that becomes the file header row
          table.insert(chunk, filename .. ':0:0:')
        end
      end
      table.insert(chunk, line)
    end

    local result = async.await(3, vim.system, cmd, {
      text = true,
      stdout = function(err, data)
        assert(not err)

        if data then
          -- stdout arrives in arbitrary chunks: the last line may be cut in
          -- half, so only consume lines that end with '\n' and keep the rest.
          data = pending .. data
          local lines = vim.split(data, '\n', { plain = true })
          pending = table.remove(lines)
          for _, line in ipairs(lines) do
            if line ~= '' then
              parse_line(line)
            end
          end
        elseif pending ~= '' then
          parse_line(pending) -- final line without a trailing newline
          pending = ''
        end

        local done = data == nil
        local process = {}
        if done then
          -- EOF: flush whatever is left, even if it is less than batch_size.
          -- (This was the main bug: the tail never reached setqflist.)
          process, chunk = chunk, {}
        elseif #chunk >= batch_size then
          for i = 1, batch_size do
            process[i] = chunk[i]
          end
          local rest = {}
          for i = batch_size + 1, #chunk do
            rest[#rest + 1] = chunk[i]
          end
          chunk = rest
        end

        if #process == 0 and not done then
          return -- still accumulating, nothing to flush yet
        end

        local count = total -- snapshot; upvalues keep mutating after schedule
        vim.schedule(function()
          if not is_quick and not api.nvim_win_is_valid(owner) then
            return
          end

          if #process > 0 or not opened then
            qf_fn({}, id and 'a' or ' ', {
              lines = process,
              id = id,
              efm = '%f:%l:%c:%m,%f:%l:%m',
              title = title,
              quickfixtextfunc = qf_text,
            })
            if not id then
              id = is_quick and fn.getqflist({ id = 0 }).id or fn.getloclist(owner, { id = 0 }).id
            end
          end

          if not opened then
            if not is_quick and api.nvim_get_current_win() ~= owner then
              api.nvim_set_current_win(owner)
            end
            vim.cmd(is_quick and 'copen' or 'lopen')
            state.buf = api.nvim_get_current_buf()
            state.win = api.nvim_get_current_win()
            setup_init(state.buf, is_quick)
            opened = true
          end

          state.count = count
          state.done = done
          update_title()
        end)
      end,
    })

    -- Exit code 1 just means "no matches" for grep/rg; only >1 is an error.
    if result.code > 1 then
      vim.schedule(function()
        local msg = (result.stderr and result.stderr ~= '') and ('\n' .. result.stderr) or ''
        vim.notify('Grep failed with exit code: ' .. result.code .. msg, vim.log.levels.ERROR)
      end)
    end
  end)
end

api.nvim_create_user_command('Grep', function(opts)
  grep(LOCAL, unpack(opts.fargs))
end, { nargs = '+', complete = 'file_in_path', desc = 'Search using location list' })

api.nvim_create_user_command('GREP', function(opts)
  grep(QUICK, unpack(opts.fargs))
end, { nargs = '+', complete = 'file_in_path', desc = 'Search using quickfix list' })

api.nvim_create_autocmd('CmdlineEnter', {
  pattern = ':',
  callback = function()
    vim.cmd(
      [[cnoreabbrev <expr> grep (getcmdtype() ==# ':' && getcmdline() ==# 'grep') ? 'Grep' : 'grep']]
    )
  end,
})
