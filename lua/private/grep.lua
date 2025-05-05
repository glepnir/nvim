local api, QUICK, LOCAL, FORWARD, BACKWARD, mapset = vim.api, 1, 2, 1, 2, vim.keymap.set
local treesitter = vim.treesitter

local preview = {
  win = nil,
  enabled = true,
}

local function create_preview_window(bufnr)
  if preview.buf and api.nvim_buf_is_valid(preview.buf) then
    api.nvim_buf_delete(preview.buf, { force = true })
  end

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
end

local function update_preview()
  if not preview.enabled then
    return
  end

  local win_id = api.nvim_get_current_win()
  local win_info = vim.fn.getwininfo(win_id)[1]

  local is_loclist = win_info.loclist == 1

  local idx = vim.fn.line('.')
  local list = is_loclist and vim.fn.getloclist(0) or vim.fn.getqflist()

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

local function toggle_preview()
  preview.enabled = not preview.enabled
  if preview.enabled then
    update_preview()
  elseif preview.win and api.nvim_win_is_valid(preview.win) then
    api.nvim_win_close(preview.win, true)
    preview.win = nil
  end
end

api.nvim_create_autocmd('FileType', {
  pattern = 'qf',
  callback = function()
    vim.opt_local.wrap = false
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.signcolumn = 'no'

    local buf = api.nvim_get_current_buf()

    local move = function(dir)
      return function()
        api.nvim_buf_call(buf, function()
          pcall(vim.cmd, dir == FORWARD and 'cnext' or 'cprev')
          update_preview()
        end)
      end
    end

    mapset('n', 'q', function()
      if preview.win and api.nvim_win_is_valid(preview.win) then
        api.nvim_win_close(preview.win, true)
        preview.win = nil
      end
      vim.cmd('cclose')
    end, { buffer = buf })

    mapset('n', '<C-n>', move(FORWARD), { buffer = buf })
    mapset('n', '<C-p>', move(BACKWARD), { buffer = buf })

    mapset('n', '<CR>', function()
      vim.cmd('normal! <CR>zz')
      if preview.win and api.nvim_win_is_valid(preview.win) then
        api.nvim_win_close(preview.win, true)
        preview.win = nil
      end
    end, { buffer = buf })

    mapset('n', 'p', toggle_preview, { buffer = buf })

    api.nvim_create_autocmd('CursorMoved', {
      buffer = buf,
      callback = update_preview,
    })

    update_preview()
  end,
})

local grep = async(function(t, ...)
  local args = { ... }
  local grepprg = vim.o.grepprg
  local cmd = vim.split(grepprg, '%s+', { trimempty = true })
  local fn = t == QUICK and function(...)
    vim.fn.setqflist(...)
  end or function(...)
    vim.fn.setloclist(0, ...)
  end

  for _, arg in ipairs(args) do
    table.insert(cmd, arg)
  end
  table.insert(cmd, '--fixed-strings')

  local opened = false
  local result = try_await(asystem(cmd, {
    text = true,
    stdout = function(err, data)
      assert(not err)
      if data then
        vim.schedule(function()
          local lines = vim.split(data, '\n', { trimempty = true })
          if #lines > 0 then
            fn({}, 'a', {
              lines = lines,
              efm = vim.o.errorformat,
              title = 'Grep',
            })
            if not opened then
              vim.cmd(t == QUICK and 'cw' or 'lw')
              opened = true
            end
          end
        end)
      end
    end,
  }))

  if result.error then
    return vim.notify('Grep failed: ' .. tostring(result.error.message or ''), vim.log.levels.ERROR)
  end
end)

api.nvim_create_user_command('Grep', function(opts)
  grep(QUICK, opts.args)
end, { nargs = '+', complete = 'file_in_path', desc = 'Search using quickfix list' })

api.nvim_create_user_command('GREP', function(opts)
  grep(LOCAL, opts.args)
end, { nargs = '+', complete = 'file_in_path', desc = 'Search using location list' })

api.nvim_create_autocmd('CmdlineEnter', {
  pattern = ':',
  callback = function()
    vim.cmd(
      [[cnoreabbrev <expr> grep (getcmdtype() ==# ':' && getcmdline() ==# 'grep') ? 'Grep' : 'grep']]
    )
    vim.cmd(
      [[cnoreabbrev <expr> lgrep (getcmdtype() ==# ':' && getcmdline() ==# 'lgrep') ? 'LGrep' : 'lgrep']]
    )
  end,
})
