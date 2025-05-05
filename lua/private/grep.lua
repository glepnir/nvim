local api, QUICK, LOCAL, FORWARD, BACKWARD, mapset = vim.api, 1, 2, 1, 2, vim.keymap.set
local treesitter = vim.treesitter
local ns_qf = api.nvim_create_namespace('quickfix_highlight')

local preview = {
  win = nil,
  enabled = false,
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

  api.nvim_create_autocmd('WinClosed', {
    buffer = api.nvim_get_current_buf(),
    once = true,
    callback = function()
      api.nvim_win_close(preview.win, true)
    end,
  })
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

local function toggle_preview(buf)
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

local function setup_init(buf)
  vim.opt_local.wrap = false
  vim.opt_local.number = false
  vim.opt_local.relativenumber = false
  vim.opt_local.signcolumn = 'no'

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

  mapset('n', 'p', function()
    toggle_preview(buf)
  end, { buffer = buf })
end

local function highlight_qf(buf)
  api.nvim_create_autocmd('TextChanged', {
    buffer = buf,
    callback = function()
      local lines = api.nvim_buf_get_lines(buf, 0, -1, false)
      for i, line in ipairs(lines) do
        local line_idx = i - 1

        local file_end = line:find(' → ')
        if file_end then
          api.nvim_buf_set_extmark(buf, ns_qf, line_idx, 0, {
            end_row = line_idx,
            end_col = file_end - 1,
            hl_group = 'Keyword',
          })

          api.nvim_buf_set_extmark(buf, ns_qf, line_idx, file_end, {
            end_row = line_idx,
            end_col = file_end + 1,
            hl_group = 'Function',
          })

          local lnum_start = file_end + 3
          local lnum_end = line:find(':', lnum_start)
          if lnum_end then
            api.nvim_buf_set_extmark(buf, ns_qf, line_idx, lnum_start, {
              end_row = line_idx,
              end_col = lnum_end - 1,
              hl_group = 'String',
            })

            local col_start = lnum_end
            local col_end = line:find('→', col_start)
            if col_end then
              api.nvim_buf_set_extmark(buf, ns_qf, line_idx, col_start, {
                end_row = line_idx,
                end_col = col_end - 1,
                hl_group = 'String',
              })

              api.nvim_buf_set_extmark(buf, ns_qf, line_idx, col_end - 1, {
                end_row = line_idx,
                end_col = col_end + 1,
                hl_group = 'Function',
              })

              local text_start = col_end + 3
              if text_start < #line then
                api.nvim_buf_set_extmark(buf, ns_qf, line_idx, text_start, {
                  end_row = line_idx,
                  end_col = #line,
                  hl_group = 'QfText',
                })
              end
            end
          end
        end
      end
    end,
  })
end

function _G.smart_quickfix_format(info)
  local separator = info.quickfix == 1 and '→' or '•'
  local lines = {}
  local list = info.quickfix == 1 and vim.fn.getqflist() or vim.fn.getloclist(info.winid)

  local max_filename_width = 0
  for i = info.start_idx, info.end_idx do
    local item = list[i]
    if item then
      local filename = item.bufnr > 0 and vim.fn.bufname(item.bufnr) or ''
      max_filename_width = math.max(max_filename_width, #filename)
    end
  end

  for i = info.start_idx, info.end_idx do
    local item = list[i]
    if item then
      local filename = item.bufnr > 0 and vim.fn.bufname(item.bufnr) or ''
      local format_str = '%-' .. max_filename_width .. 's %s %2d:%-2d %s %s'
      local line = string.format(
        format_str,
        filename,
        separator,
        item.lnum,
        item.col,
        separator,
        item.text or ''
      )
      table.insert(lines, line)
    end
  end
  return lines
end

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
  local id = nil
  local result = try_await(asystem(cmd, {
    text = true,
    stdout = function(err, data)
      assert(not err)
      if data then
        vim.schedule(function()
          local lines = vim.split(data, '\n', { trimempty = true })
          if #lines > 0 then
            local action = 'a'
            if not opened then
              id = fn({}, 'r', {
                lines = { 'Grep searching' },
                efm = '%f',
                quickfixtextfunc = 'v:lua.smart_quickfix_format',
              })
              vim.cmd(t == QUICK and 'cw' or 'lw')
              local buf = api.nvim_get_current_buf()
              setup_init(buf)
              highlight_qf(buf)
              opened = true
              action = 'r'
            end

            fn({}, action, {
              lines = lines,
              id = id,
              efm = vim.o.errorformat,
              quickfixtextfunc = 'v:lua.smart_quickfix_format',
              title = 'Grep',
            })
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
