local api = vim.api

-- Create a smart keymap wrapper using metatables
local keymap = {}

-- Valid vim modes
local valid_modes =
  { n = true, i = true, v = true, x = true, s = true, o = true, c = true, t = true }

-- Store mode combinations we've created
local mode_cache = {}

-- Function that performs the actual mapping
local function perform_mapping(modes, lhs, rhs, opts)
  opts = opts or {}
  local mapset = vim.keymap.set

  if type(lhs) == 'table' then
    -- Handle table of mappings
    for key, action in pairs(lhs) do
      mapset(modes, key, action, opts)
    end
  else
    -- Handle single mapping
    mapset(modes, lhs, rhs, opts)
  end

  return keymap -- Return keymap for chaining
end

-- Parse a mode string into an array of mode characters
local function parse_modes(mode_str)
  local modes = {}
  for i = 1, #mode_str do
    local char = mode_str:sub(i, i)
    if valid_modes[char] then
      table.insert(modes, char)
    end
  end
  return modes
end

-- Create the metatable that powers the dynamic mode access
local mt = {
  __index = function(_, key)
    -- If this mode combination is already cached, return it
    if mode_cache[key] then
      return mode_cache[key]
    end

    -- Check if this is a valid mode string
    local modes = parse_modes(key)
    if #modes > 0 then
      -- Create and cache a function for this mode combination
      local mode_fn = function(lhs, rhs, opts)
        return perform_mapping(modes, lhs, rhs, opts)
      end

      mode_cache[key] = mode_fn
      return mode_fn
    end

    return nil -- Not a valid mode key
  end,

  -- Make the keymap table directly callable
  __call = function(_, modes, lhs, rhs, opts)
    return perform_mapping(type(modes) == 'string' and parse_modes(modes) or modes, lhs, rhs, opts)
  end,
}

local map = setmetatable(keymap, mt)

-- Helper function for command mappings
local cmd = function(command)
  return ('<cmd>%s<CR>'):format(command)
end

map.n({
  ['j'] = 'gj',
  ['k'] = 'gk',
  ['<C-s>'] = cmd('write'),
  -- ['<C-x>k'] = cmd(vim.bo.buftype == 'terminal' and 'q!' or 'BufKeepDelete'),
  ['<C-n>'] = cmd('bn'),
  ['<C-p>'] = cmd('bp'),
  ['<C-q>'] = cmd('qa!'),
  --window
  ['<C-h>'] = '<C-w>h',
  -- ['<C-l>'] = '<C-w>l',
  ['<C-j>'] = '<C-w>j',
  ['<C-k>'] = '<C-w>k',
  ['<A-[>'] = cmd('vertical resize -5'),
  ['<A-]>'] = cmd('vertical resize +5'),
  ['[t'] = cmd('vs | vertical resize -5 | terminal'),
  [']t'] = cmd('set splitbelow | sp | set nosplitbelow | resize -5 | terminal'),
  ['<C-x>t'] = cmd('tabnew | terminal'),
  ['gV'] = '`[v`]',
  ['<C-x>m'] = cmd('Compile'),
  ['<C-x>r'] = cmd('Recompile'),
  ['<C-W>['] = cmd('vertical wincmd ]'),
})

map.i({
  ['<C-d>'] = '<C-o>diw',
  ['<C-b>'] = '<Left>',
  ['<C-f>'] = '<Right>',
  ['<C-a>'] = '<Esc>^i',
  ['<C-n>'] = '<Down>',
  ['<C-p>'] = '<Up>',
  --down/up
  ['<C-j>'] = '<C-o>o',
  ['<C-l>'] = '<C-o>O',
  --@see https://github.com/neovim/neovim/issues/16416
  ['<C-C>'] = '<C-C>',
  --@see https://vim.fandom.com/wiki/Moving_lines_up_or_down
  ['<A-j>'] = '<Esc>:m .+1<CR>==gi',
})

map.i('<C-K>', function()
  local pos = vim.api.nvim_win_get_cursor(0)
  local row = pos[1]
  local col = pos[2]
  local line = vim.api.nvim_get_current_line()
  local total_lines = vim.api.nvim_buf_line_count(0)
  local trimmed_line = line:gsub('%s+$', '')
  local killed_text = ''

  if col == 0 then
    if trimmed_line == '' then
      if row < total_lines then
        killed_text = '\n'
        local next_line = api.nvim_buf_get_lines(0, row, row + 1, false)[1] or ''
        api.nvim_buf_set_lines(0, row - 1, row + 1, false, { next_line })
      end
    else
      killed_text = line
      api.nvim_set_current_line('')
    end
  else
    if col < #trimmed_line then
      killed_text = line:sub(col + 1)
      api.nvim_set_current_line(line:sub(1, col))
    else
      if row < total_lines then
        killed_text = '\n'
        local next_line = api.nvim_buf_get_lines(0, row, row + 1, false)[1] or ''
        api.nvim_buf_set_lines(0, row - 1, row + 1, false, { line .. next_line })
      end
    end
  end

  if killed_text ~= '' then
    vim.fn.setreg('+', killed_text, 'v')
  end
end)

map.c({
  ['<C-b>'] = '<Left>',
  ['<C-f>'] = '<Right>',
  ['<C-a>'] = '<Home>',
  ['<C-e>'] = '<End>',
  ['<C-d>'] = '<Del>',
  ['<C-h>'] = '<BS>',
})

map.t({
  ['<Esc>'] = [[<C-\><C-n>]],
  ['<C-x>k'] = cmd('quit'),
})

-- insert cut text to paste: first press sets the start, second press cuts
local cut_ns = api.nvim_create_namespace('my_cut_region')
map.i('<A-w>', function()
  local lnum, col = unpack(api.nvim_win_get_cursor(0))
  local marks = api.nvim_buf_get_extmarks(0, cut_ns, 0, -1, {})
  if #marks == 0 then
    api.nvim_buf_set_extmark(0, cut_ns, lnum - 1, col, {})
    return
  end
  api.nvim_buf_clear_namespace(0, cut_ns, 0, -1)
  local srow, scol, erow, ecol = marks[1][2], marks[1][3], lnum - 1, col
  if srow > erow or (srow == erow and scol > ecol) then
    srow, scol, erow, ecol = erow, ecol, srow, scol
  end
  local text = api.nvim_buf_get_text(0, srow, scol, erow, ecol, {})
  vim.fn.setreg('+', text, 'v')
  api.nvim_buf_set_text(0, srow, scol, erow, ecol, {})
  api.nvim_win_set_cursor(0, { srow + 1, scol })
end)

-- Ctrl-y works like emacs
map.i('<C-y>', function()
  if tonumber(vim.fn.pumvisible()) == 1 or vim.fn.getreg('+'):find('%w') == nil then
    return '<C-y>'
  end
  return '<Esc>p==a'
end, { expr = true })

-- move line up
map.i('<A-k>', function()
  local lnum = api.nvim_win_get_cursor(0)[1]
  if lnum == 1 then
    return ''
  end
  local line = lnum > 2 and api.nvim_buf_get_lines(0, lnum - 3, lnum - 2, false)[1] or ''
  return (lnum == 2 or #line > 0) and '<Esc>:m .-2<CR>==gi' or '<Esc>kkddj:m .-2<CR>==gi'
end, { expr = true })

map.i('<TAB>', function()
  if tonumber(vim.fn.pumvisible()) == 1 then
    return '<C-n>'
  elseif vim.snippet.active({ direction = 1 }) then
    return '<cmd>lua vim.snippet.jump(1)<cr>'
  else
    return '<TAB>'
  end
end, { expr = true })

map.i('<S-TAB>', function()
  if vim.fn.pumvisible() == 1 then
    return '<C-p>'
  elseif vim.snippet.active({ direction = -1 }) then
    return '<cmd>lua vim.snippet.jump(-1)<CR>'
  else
    return '<S-TAB>'
  end
end, { expr = true })

map.i('<CR>', function()
  if tonumber(vim.fn.pumvisible()) == 1 then
    return '<C-y>'
  end
  local line = api.nvim_get_current_line()
  local col = api.nvim_win_get_cursor(0)[2]
  local before = line:sub(col, col)
  local after = line:sub(col + 1, col + 1)
  local t = {
    ['('] = ')',
    ['['] = ']',
    ['{'] = '}',
  }
  if t[before] and t[before] == after then
    return '<CR><ESC>O'
  end
  return '<CR>'
end, { expr = true })

map.i('<C-e>', function()
  return vim.fn.pumvisible() == 1 and '<C-e>' or '<End>'
end, { expr = true })

local ns_id, mark_id, mark_buf = vim.api.nvim_create_namespace('my_marks'), nil, nil

map.i('<C-t>', function()
  if
    mark_id and (mark_buf ~= api.nvim_get_current_buf() or not api.nvim_buf_is_valid(mark_buf))
  then
    pcall(api.nvim_buf_del_extmark, mark_buf, ns_id, mark_id)
    mark_id = nil
  end
  if not mark_id then
    local row, col = unpack(api.nvim_win_get_cursor(0))
    mark_buf = api.nvim_get_current_buf()
    mark_id = api.nvim_buf_set_extmark(0, ns_id, row - 1, col, {
      virt_text = { { '⚑', 'DiagnosticError' } },
      hl_group = 'Search',
      virt_text_pos = 'inline',
    })
    return
  end
  local mark = api.nvim_buf_get_extmark_by_id(0, ns_id, mark_id, {})
  if not mark or #mark == 0 then
    mark_id = nil
    return
  end
  pcall(api.nvim_win_set_cursor, 0, { mark[1] + 1, mark[2] })
  api.nvim_buf_del_extmark(0, ns_id, mark_id)
  mark_id = nil
end)

-- gX: Web search
map.n('gX', function()
  vim.ui.open(('https://google.com/search?q=%s'):format(vim.fn.expand('<cword>')))
end)

map.x('gX', function()
  local lines = vim.fn.getregion(vim.fn.getpos('.'), vim.fn.getpos('v'), { type = vim.fn.mode() })
  vim.ui.open(('https://google.com/search?q=%s'):format(vim.trim(table.concat(lines, ' '))))
  api.nvim_input('<esc>')
end)

map.n('gs', function()
  local bufnr = api.nvim_create_buf(false, false)
  vim.bo[bufnr].buftype = 'prompt'
  vim.fn.prompt_setprompt(bufnr, ' ')
  api.nvim_buf_set_extmark(bufnr, api.nvim_create_namespace('WebSearch'), 0, 0, {
    line_hl_group = 'String',
  })
  local width = math.floor(vim.o.columns * 0.5)
  local winid = api.nvim_open_win(bufnr, true, {
    relative = 'editor',
    row = 5,
    width = width,
    height = 5,
    col = math.floor(vim.o.columns / 2) - math.floor(width / 2),
    border = 'rounded',
    title = 'Google Search',
    title_pos = 'center',
  })
  vim.cmd.startinsert()
  vim.wo[winid].number = false
  vim.wo[winid].stc = ''
  vim.wo[winid].lcs = 'trail: '
  vim.wo[winid].wrap = true
  vim.wo[winid].signcolumn = 'no'
  vim.fn.prompt_setcallback(bufnr, function(text)
    vim.ui.open(('https://google.com/search?q=%s'):format(vim.trim(text)))
    api.nvim_win_close(winid, true)
  end)
  vim.keymap.set({ 'n', 'i' }, '<C-c>', function()
    pcall(api.nvim_win_close, winid, true)
  end, { buf = bufnr })
end)

map.n('<Leader>a', function() end)

map.n({
  -- ['gl'] = cmd('Visualizer full'),
  -- FzfLua
  ['<Leader>d'] = cmd('FzfLua diagnostics_document'),
  ['<Leader>D'] = cmd('FzfLua diagnostics_workspace'),
  ['<Leader>b'] = cmd('FzfLua buffers'),
  ['<Leader>fa'] = cmd('FzfLua live_grep_native'),
  ['<Leader>fs'] = cmd('FzfLua grep_cword'),
  ['<Leader>ff'] = cmd('FzfLua files'),
  ['<Leader>fh'] = cmd('FzfLua helptags'),
  ['<Leader>fo'] = cmd('FzfLua oldfiles'),
  ['<Leader>fg'] = cmd('FzfLua git_files'),
  ['<Leader>gc'] = cmd('FzfLua git_commits'),
  ['<Leader>gb'] = cmd('FzfLua git_bcommits'),
  ['<Leader>o'] = cmd('FzfLua lsp_document_symbols'),
  ['<Leader>fc'] = cmd('FzfLua files cwd=$HOME/.config fd_opts=--type\\ f'),
  --gitsign
  [']g'] = cmd('lua pcall(function() require"gitsigns".nav_hunk("next") end)'),
  ['[g'] = cmd('lua pcall(function() require"gitsigns".nav_hunk("prev") end)'),
})

map.n('<C-X><C-f>', cmd('Dired'))

map.nt('<A-d>', function()
  require('term').toggle()
end)
-- map.nx('ga', cmd('Lspsaga code_action'))

map.n('f', function()
  local j = require('jump')
  if j.charForward then
    j.charForward()
  end
end)

map.n('F', function()
  local j = require('jump')
  if j.charBackward then
    j.charBackward()
  end
end)

vim.cmd([[
iabbrev <expr> ,d strftime('%Y-%m-%d')
iabbrev <expr> ,t strftime('%Y-%m-%d %H:%M')
]])

map.xo('af', function()
  require('nvim-treesitter-textobjects.select').select_textobject('@function.outer', 'textobjects')
end)
map.xo('if', function()
  require('nvim-treesitter-textobjects.select').select_textobject('@function.inner', 'textobjects')
end)
map.xo('ac', function()
  require('nvim-treesitter-textobjects.select').select_textobject('@class.outer', 'textobjects')
end)
map.xo('ic', function()
  require('nvim-treesitter-textobjects.select').select_textobject('@class.inner', 'textobjects')
end)
map.xo('as', function()
  require('nvim-treesitter-textobjects.select').select_textobject('@local.scope', 'locals')
end)

-- https://slicker.me/neovim/boosting_productivity_lua.htm
-- keep builtin ]c/[c in diff mode
local comment_pat = [[^\s*//\|^\s*#\|^\s*\*\s]]
map.nxo(']c', function()
  if vim.wo.diff then
    return ']c'
  end
  return ("<Cmd>call search('%s', 'W')<CR>"):format(comment_pat)
end, { expr = true, desc = 'Next comment' })

map.nxo('[c', function()
  if vim.wo.diff then
    return '[c'
  end
  return ("<Cmd>call search('%s', 'bW')<CR>"):format(comment_pat)
end, { expr = true, desc = 'Prev comment' })

map.c('<CR>', function()
  local res = vim.fn.cmdcomplete_info()
  local skip = { 'w', 'q', 'wq', 'ccl', 'lcl' }
  if vim.list_contains(skip, res.cmdline_orig) then
    return '<CR>'
  end
  return vim.fn.pumvisible() == 1 and '<C-y>' or '<CR>'
end, { expr = true })
