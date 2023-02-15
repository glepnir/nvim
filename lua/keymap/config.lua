local api = vim.api

local function before_words()
  local line = api.nvim_get_current_line()
  local col = api.nvim_win_get_cursor(0)[2]
  return line:sub(0, col)
end

local function luasnip_status()
  local ok, luasnip = pcall(require, 'luasnip')
  if not ok then
    return false
  end
  return luasnip.expand_or_jumpable()
end

_G.smart_tab = function()
  local words = before_words()

  if not words:match('%S') then
    return '<TAB>'
  end

  if luasnip_status() then
    return '<Plug>luasnip-expand-or-jump'
  end

  if vim.fn.pumvisible() == 1 then
    return '<C-n>'
  end

  local has_period = words:match('.')
  local has_slash = words:match('/')
  print(has_period, has_slash)
  if not has_period and not has_slash then
    return '<C-X><C-P>'
  elseif has_slash then
    return '<C-X><C-F>'
  else
    return '<C-X><C-O>'
  end
end
