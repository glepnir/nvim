--My personal completion.
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

local function map_tab()
  local words = before_words()

  if not words:match('%S') then
    return '<TAB>'
  end

  if luasnip_status() then
    return '<Plug>luasnip-expand-or-jump'
  end

  if vim.fn.pumvisible() == 1 then
    return '<Down>'
  end

  local has_period = words:match('.')
  local has_slash = words:match('/')

  if not has_period and not has_slash then
    return '<C-X><C-P>'
  elseif has_slash then
    return '<C-X><C-F>'
  else
    return '<C-X><C-O>'
  end
end

local function feedkeys(key, mode)
  local keycode = api.nvim_replace_termcodes(key, true, false, true)
  api.nvim_feedkeys(keycode, mode, false)
end

local function lua_func(item)
  if
    vim.bo.filetype == 'lua'
    and (item.kind == 'Field' or item.kind == 'Text')
    and item.word:find('nvim_')
  then
    return true
  end
  return false
end

local function insert_bracket()
  if not vim.v.completed_item or vim.tbl_isempty(vim.v.completed_item) then
    return
  end

  local item = vim.v.completed_item
  if (item.kind == 'Function' or lua_func(item)) and not item.word:find('%(') then
    feedkeys('()', 't')
    feedkeys('<Left>', 'n')
  end
end

local function map_cr()
  local npairs = require('nvim-autopairs')
  if vim.fn.pumvisible() == 1 then
    feedkeys('<C-y>', 'n')
    insert_bracket()
  else
    local key = npairs.autopairs_cr()
    api.nvim_feedkeys(key, 'n', false)
  end
end

api.nvim_create_autocmd('CompleteDonePre', {
  callback = function(args)
    local textedits = vim.tbl_get(
      vim.v.completed_item,
      'user_data',
      'nvim',
      'lsp',
      'completion_item',
      'additionalTextEdits'
    )
    if textedits then
      vim.lsp.util.apply_text_edits(textedits, args.buf, 'utf-16')
    end
  end,
})

local mapped = false
local function epoch()
  if mapped then
    return
  end
  local map = require('core.keymap')

  local opt = { expr = true, remap = true }
  map.i({ ['<TAB>'] = map_tab, ['<CR>'] = map_cr }, opt)
end

return {
  epoch = epoch,
}
