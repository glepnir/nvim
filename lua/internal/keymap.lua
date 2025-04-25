-- local map = require('core.keymap')
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

  if type(lhs) == 'table' then
    -- Handle table of mappings
    for key, action in pairs(lhs) do
      vim.keymap.set(modes, key, action, opts)
    end
  else
    -- Handle single mapping
    vim.keymap.set(modes, lhs, rhs, opts)
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
    if type(modes) == 'string' then
      -- Convert string to mode list
      return perform_mapping(parse_modes(modes), lhs, rhs, opts)
    else
      -- Assume modes is already a list
      return perform_mapping(modes, lhs, rhs, opts)
    end
  end,
}

local map = setmetatable(keymap, mt)

-- Helper function for command mappings
local cmd = function(command)
  return '<cmd>' .. command .. '<CR>'
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
  ['<C-l>'] = '<C-w>l',
  ['<C-j>'] = '<C-w>j',
  ['<C-k>'] = '<C-w>k',
  ['<A-[>'] = cmd('vertical resize -5'),
  ['<A-]>'] = cmd('vertical resize +5'),
  ['[t'] = cmd('vs | vertical resize -5 | terminal'),
  [']t'] = cmd('set splitbelow | sp | set nosplitbelow | resize -5 | terminal'),
  ['<C-x>t'] = cmd('tabnew | terminal'),
  ['gV'] = '`[v`]',
})

map.i({
  ['<C-d>'] = '<C-o>diw',
  ['<C-b>'] = '<Left>',
  ['<C-f>'] = '<Right>',
  ['<C-a>'] = '<Esc>^i',
  ['<C-s>'] = '<ESC>:w<CR>',
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

-- insert cut text to paste
map.i('<A-w>', function()
  local mark = vim.api.nvim_buf_get_mark(0, 'a')
  local lnum, col = unpack(api.nvim_win_get_cursor(0))
  if mark[1] == 0 then
    api.nvim_buf_set_mark(0, 'a', lnum, col, {})
  else
    local keys = '<ESC>d`aa'
    api.nvim_feedkeys(api.nvim_replace_termcodes(keys, true, true, true), 'n', false)
    vim.schedule(function()
      api.nvim_buf_del_mark(0, 'a')
    end)
  end
end)

-- Ctrl-y works like emacs
map.i('<C-y>', function()
  if tonumber(vim.fn.pumvisible()) == 1 or vim.fn.getreg('"+'):find('%w') == nil then
    return '<C-y>'
  end
  return '<Esc>p==a'
end, { expr = true })

-- move line down
map.i('<A-k>', function()
  local lnum = api.nvim_win_get_cursor(0)[1]
  local line = api.nvim_buf_get_lines(0, lnum - 3, lnum - 2, false)[1]
  return #line > 0 and '<Esc>:m .-2<CR>==gi' or '<Esc>kkddj:m .-2<CR>==gi'
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
  if vim.fn.pumvisible() == 1 then
    return '<C-e>'
  else
    return '<End>'
  end
end, { expr = true })

local ns_id, mark_id = vim.api.nvim_create_namespace('my_marks'), nil

map.i('<C-t>', function()
  if not mark_id then
    local row, col = unpack(api.nvim_win_get_cursor(0))
    mark_id = api.nvim_buf_set_extmark(0, ns_id, row - 1, col, {
      virt_text = { { '⚑', 'DiagnosticError' } },
      hl_group = 'Search',
      virt_text_pos = 'inline',
    })
    return
  end
  local mark = api.nvim_buf_get_extmark_by_id(0, ns_id, mark_id, {})
  if not mark or #mark == 0 then
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
    height = 1,
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
  end, { buffer = bufnr })
end)

map.n({
  -- Lspsaga
  ['[d'] = cmd('Lspsaga diagnostic_jump_next'),
  [']d'] = cmd('Lspsaga diagnostic_jump_prev'),
  ['K'] = cmd('Lspsaga hover_doc'),
  ['ga'] = cmd('Lspsaga code_action'),
  ['gr'] = cmd('Lspsaga rename'),
  ['gd'] = cmd('Lspsaga peek_definition'),
  ['gp'] = cmd('Lspsaga goto_definition'),
  ['gh'] = cmd('Lspsaga finder'),
  -- ['<Leader>o'] = cmd('Lspsaga outline'),
  -- dbsession
  ['<Leader>ss'] = cmd('SessionSave'),
  ['<Leader>sl'] = cmd('SessionLoad'),
  -- FzfLua
  ['<Leader>b'] = cmd('FzfLua buffers'),
  ['<Leader>fa'] = cmd('FzfLua live_grep_native'),
  ['<Leader>fs'] = cmd('FzfLua grep_cword'),
  ['<Leader>ff'] = cmd('FzfLua files'),
  ['<Leader>fh'] = cmd('FzfLua helptags'),
  ['<Leader>fo'] = cmd('FzfLua oldfiles'),
  ['<Leader>fg'] = cmd('FzfLua git_files'),
  ['<Leader>gc'] = cmd('FzfLua git_commits'),
  ['<Leader>o'] = cmd('FzfLua lsp_document_symbols'),
  ['<Leader>fc'] = cmd('FzfLua files cwd=$HOME/.config'),
  -- flybuf.nvim
  ['<Leader>j'] = cmd('FlyBuf'),
  --gitsign
  [']g'] = cmd('lua require"gitsigns".next_hunk()<CR>'),
  ['[g'] = cmd('lua require"gitsigns".prev_hunk()<CR>'),
})

map.ni('<C-X><C-f>', cmd('Dired'))

--template.nvim
map.n('<Leader>t', function()
  local tmp_name
  if vim.bo.filetype == 'lua' then
    tmp_name = 'nvim_temp'
  end
  if tmp_name then
    vim.cmd('Template ' .. tmp_name)
    return
  end
  return ':Template '
end, { expr = true })

-- Lspsaga floaterminal
map.nt('<A-d>', cmd('Lspsaga term_toggle'))

map.nx('ga', cmd('Lspsaga code_action'))
