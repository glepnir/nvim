local api = vim.api
local M = {}
local H = {}

M.setup = function(config)
  _G.PairMate = M
  config = H.setup_config(config)
  H.apply_config(config)
  H.create_autocommands()
end

M.config = {
  modes = { insert = true, command = false, terminal = false },

  mappings = {
    ['('] = { action = 'open', pair = '()', neigh_pattern = '[^\\].' },
    ['['] = { action = 'open', pair = '[]', neigh_pattern = '[^\\].' },
    ['{'] = { action = 'open', pair = '{}', neigh_pattern = '[^\\].' },

    [')'] = { action = 'close', pair = '()', neigh_pattern = '[^\\].' },
    [']'] = { action = 'close', pair = '[]', neigh_pattern = '[^\\].' },
    ['}'] = { action = 'close', pair = '{}', neigh_pattern = '[^\\].' },

    ['"'] = {
      action = 'closeopen',
      pair = '""',
      neigh_pattern = '[^\\].',
      register = { cr = false },
    },
    ["'"] = {
      action = 'closeopen',
      pair = "''",
      neigh_pattern = '[^%a&\\].',
      register = { cr = false },
    },
    ['`'] = {
      action = 'closeopen',
      pair = '``',
      neigh_pattern = '[^\\].',
      register = { cr = false },
    },
  },
}

M.map = function(mode, lhs, pair_info, opts)
  pair_info = H.validate_pair_info(pair_info)
  opts = vim.tbl_deep_extend('force', opts or {}, { expr = true, noremap = true })
  opts.desc = H.infer_mapping_description(pair_info)

  api.nvim_set_keymap(mode, lhs, H.pair_info_to_map_rhs(pair_info), opts)
  H.register_pair(pair_info, mode, 'all')

  H.ensure_cr_bs(mode)
end

M.map_buf = function(buffer, mode, lhs, pair_info, opts)
  pair_info = H.validate_pair_info(pair_info)
  opts = vim.tbl_deep_extend('force', opts or {}, { expr = true, noremap = true })
  opts.desc = H.infer_mapping_description(pair_info)

  api.nvim_buf_set_keymap(buffer, mode, lhs, H.pair_info_to_map_rhs(pair_info), opts)
  H.register_pair(pair_info, mode, buffer == 0 and api.nvim_get_current_buf() or buffer)

  H.ensure_cr_bs(mode)
end

M.unmap = function(mode, lhs, pair)
  vim.validate({ pair = { pair, 'string' } })

  pcall(api.nvim_del_keymap, mode, lhs)
  if pair == '' then
    return
  end
  H.unregister_pair(pair, mode, 'all')
end

M.unmap_buf = function(buffer, mode, lhs, pair)
  vim.validate({ pair = { pair, 'string' } })

  pcall(api.nvim_buf_del_keymap, buffer, mode, lhs)
  if pair == '' then
    return
  end
  H.unregister_pair(pair, mode, buffer == 0 and api.nvim_get_current_buf() or buffer)
end

M.open = function(pair, neigh_pattern)
  if H.is_disabled() or not H.neigh_match(neigh_pattern) then
    return pair:sub(1, 1)
  end

  return ('%s%s'):format(pair, H.get_arrow_key('left'))
end

M.close = function(pair, neigh_pattern)
  if H.is_disabled() or not H.neigh_match(neigh_pattern) then
    return pair:sub(2, 2)
  end

  local close = pair:sub(2, 2)
  if H.get_cursor_neigh(1, 1) == close then
    return H.get_arrow_key('right')
  else
    return close
  end
end

M.closeopen = function(pair, neigh_pattern)
  if H.is_disabled() or H.get_cursor_neigh(1, 1) ~= pair:sub(2, 2) then
    return M.open(pair, neigh_pattern)
  else
    return H.get_arrow_key('right')
  end
end

M.bs = function(key)
  local res = key or H.keys.bs

  local neigh = H.get_cursor_neigh(0, 1)
  if not H.is_disabled() and H.is_pair_registered(neigh, vim.fn.mode(), 0, 'bs') then
    res = ('%s%s'):format(res, H.keys.del)
  end

  return res
end

M.cr = function(key)
  local res = key or H.keys.cr

  local neigh = H.get_cursor_neigh(0, 1)
  if not H.is_disabled() and H.is_pair_registered(neigh, vim.fn.mode(), 0, 'cr') then
    res = ('%s%s'):format(res, H.keys.above)
  end

  return res
end

H.default_config = vim.deepcopy(M.config)

H.default_pair_info = { neigh_pattern = '..', register = { bs = true, cr = true } }

H.registered_pairs = {
  i = { all = { bs = {}, cr = {} } },
  c = { all = { bs = {}, cr = {} } },
  t = { all = { bs = {}, cr = {} } },
}

local function escape(s)
  return api.nvim_replace_termcodes(s, true, true, true)
end
H.keys = {
  above = escape('<C-o>O'),
  bs = escape('<bs>'),
  cr = escape('<cr>'),
  del = escape('<del>'),
  keep_undo = escape('<C-g>U'),
  left = escape('<left>'),
  right = escape('<right>'),
}

H.setup_config = function(config)
  vim.validate({ config = { config, 'table', true } })
  config = vim.tbl_deep_extend('force', vim.deepcopy(H.default_config), config or {})

  vim.validate({
    modes = { config.modes, 'table' },
    mappings = { config.mappings, 'table' },
  })

  vim.validate({
    ['modes.insert'] = { config.modes.insert, 'boolean' },
    ['modes.command'] = { config.modes.command, 'boolean' },
    ['modes.terminal'] = { config.modes.terminal, 'boolean' },
  })

  return config
end

H.apply_config = function(config)
  M.config = config

  local mode_ids = { insert = 'i', command = 'c', terminal = 't' }
  local mode_array = {}
  for name, to_set in pairs(config.modes) do
    if to_set then
      table.insert(mode_array, mode_ids[name])
    end
  end

  local map_conditionally = function(mode, key, pair_info)
    if pair_info == false then
      return
    end

    M.map(mode, key, pair_info)
  end

  for _, mode in pairs(mode_array) do
    for key, pair_info in pairs(config.mappings) do
      map_conditionally(mode, key, pair_info)
    end
  end
end

H.create_autocommands = function()
  local augroup = api.nvim_create_augroup('PairMate', {})

  local au = function(event, pattern, callback, desc)
    api.nvim_create_autocmd(
      event,
      { group = augroup, pattern = pattern, callback = callback, desc = desc }
    )
  end

  au('FileType', { 'TelescopePrompt', 'fzf' }, function()
    vim.b.minipairs_disable = true
  end, 'Disable locally')
end

H.is_disabled = function()
  return vim.g.minipairs_disable == true or vim.b.minipairs_disable == true
end

H.register_pair = function(pair_info, mode, buffer)
  H.registered_pairs[mode] = H.registered_pairs[mode] or { all = { bs = {}, cr = {} } }
  local mode_pairs = H.registered_pairs[mode]

  mode_pairs[buffer] = mode_pairs[buffer] or { bs = {}, cr = {} }

  local register, pair = pair_info.register, pair_info.pair
  if register.bs and not vim.tbl_contains(mode_pairs[buffer].bs, pair) then
    table.insert(mode_pairs[buffer].bs, pair)
  end
  if register.cr and not vim.tbl_contains(mode_pairs[buffer].cr, pair) then
    table.insert(mode_pairs[buffer].cr, pair)
  end
end

H.unregister_pair = function(pair, mode, buffer)
  local mode_pairs = H.registered_pairs[mode]
  if not (mode_pairs and mode_pairs[buffer]) then
    return
  end

  local buf_pairs = mode_pairs[buffer]
  for _, key in ipairs({ 'bs', 'cr' }) do
    for i, p in ipairs(buf_pairs[key]) do
      if p == pair then
        table.remove(buf_pairs[key], i)
      end
    end
  end
end

H.is_pair_registered = function(pair, mode, buffer, key)
  local mode_pairs = H.registered_pairs[mode]
  if not mode_pairs then
    return false
  end

  if vim.tbl_contains(mode_pairs['all'][key], pair) then
    return true
  end

  buffer = buffer == 0 and api.nvim_get_current_buf() or buffer
  local buf_pairs = mode_pairs[buffer]
  if not buf_pairs then
    return false
  end

  return vim.tbl_contains(buf_pairs[key], pair)
end

H.ensure_cr_bs = function(mode)
  local has_any_cr_pair, has_any_bs_pair = false, false
  for _, pair_tbl in pairs(H.registered_pairs[mode]) do
    has_any_cr_pair = has_any_cr_pair or not vim.tbl_isempty(pair_tbl.cr)
    has_any_bs_pair = has_any_bs_pair or not vim.tbl_isempty(pair_tbl.bs)
  end

  if has_any_bs_pair then
    local opts =
      { silent = mode ~= 'c', expr = true, replace_keycodes = false, desc = 'PairMate <BS>' }
    H.map(mode, '<BS>', 'v:lua.PairMate.bs()', opts)
  end

  --Dont'map CR default
  -- if mode == 'i' and has_any_cr_pair then
  --   local opts = { expr = true, replace_keycodes = false, desc = 'PairMate <CR>' }
  --   H.map(mode, '<CR>', 'v:lua.PairMate.cr()', opts)
  -- end
end

H.validate_pair_info = function(pair_info, prefix)
  prefix = prefix or 'pair_info'
  vim.validate({ [prefix] = { pair_info, 'table' } })
  pair_info = vim.tbl_deep_extend('force', H.default_pair_info, pair_info)

  vim.validate({
    [prefix .. '.action'] = { pair_info.action, 'string' },
    [prefix .. '.pair'] = { pair_info.pair, 'string' },
    [prefix .. '.neigh_pattern'] = { pair_info.neigh_pattern, 'string' },
    [prefix .. '.register'] = { pair_info.register, 'table' },
  })

  vim.validate({
    [prefix .. '.register.bs'] = { pair_info.register.bs, 'boolean' },
    [prefix .. '.register.cr'] = { pair_info.register.cr, 'boolean' },
  })

  return pair_info
end

H.pair_info_to_map_rhs = function(pair_info)
  return ('v:lua.PairMate.%s(%s, %s)'):format(
    pair_info.action,
    vim.inspect(pair_info.pair),
    vim.inspect(pair_info.neigh_pattern)
  )
end

H.infer_mapping_description = function(pair_info)
  local action_name = pair_info.action:sub(1, 1):upper() .. pair_info.action:sub(2)
  return ('%s action for %s pair'):format(action_name, vim.inspect(pair_info.pair))
end

H.get_cursor_neigh = function(start, finish)
  local line, col
  if api.nvim_get_mode().mode == 'c' then
    line = vim.fn.getcmdline()
    col = vim.fn.getcmdpos()
    start = start - 1
    finish = finish - 1
  else
    line = api.nvim_get_current_line()
    col = api.nvim_win_get_cursor(0)[2]
  end

  return string.sub(('%s%s%s'):format('\r', line, '\n'), col + 1 + start, col + 1 + finish)
end

H.neigh_match = function(pattern)
  return (pattern == nil) or (H.get_cursor_neigh(0, 1):find(pattern) ~= nil)
end

H.get_arrow_key = function(key)
  if api.nvim_get_mode().mode == 'i' then
    return H.keys.keep_undo .. H.keys[key]
  else
    return H.keys[key]
  end
end

H.map = function(mode, lhs, rhs, opts)
  if lhs == '' then
    return
  end
  opts = vim.tbl_deep_extend('force', { silent = true }, opts or {})
  vim.keymap.set(mode, lhs, rhs, opts)
end

return M
