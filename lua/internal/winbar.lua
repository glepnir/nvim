local api = vim.api
local winbar = {}

local ns_prefix = '%#MyWinbar#test%*'

local function config_winbar()
  local ok, lspsaga = pcall(require, 'lspsaga.symbolwinbar')
  local sym
  if ok then
    sym = lspsaga.get_symbol_node()
  end
  local win_val = ''
  win_val = ns_prefix
  if sym ~= nil then
    win_val = win_val .. sym
  end
  api.nvim_win_set_option(0, 'winbar', win_val)
end

api.nvim_create_autocmd({ 'BufEnter', 'BufWinEnter', 'CursorMoved' }, {
  pattern = '*.lua',
  callback = config_winbar,
})

return winbar
