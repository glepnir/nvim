local has_words_before = function()
  local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
end

local t = function(str)
  return vim.api.nvim_replace_termcodes(str, true, true, true)
end

--- move to prev/next item in completion menuone
--- jump to prev/next snippet's placeholder
_G.smart_tab = function()
  local cmp = require('cmp')
  local ok,luasnip = pcall(require,'luasnip')
  local luasnip_status = false
  if ok then
    luasnip_status = luasnip.expand_or_jumpable()
  end

  if cmp.visible() and not luasnip_status then
    return t "<C-n>"
  elseif luasnip_status then
    return t "<Plug>luasnip-expand-or-jump"
  elseif has_words_before() then
    return t "<Tab>"
  else
    return t "<Tab>"
  end
end

_G.smart_shift_tab = function()
  local cmp = require('cmp')
  local _,luasnip = pcall(require,'luasnip')

  if cmp.visible() then
    return t "<C-p>"
  elseif luasnip.jumpable(-1) then
    return t "<cmd>lua require'luasnip'.jump(-1)<CR>"
  else
    return t "<S-Tab>"
  end
end

_G.enhance_jk_move = function(key)
  if packer_plugins['accelerated-jk'] and not packer_plugins['accelerated-jk'].loaded then
    vim.cmd [[packadd accelerated-jk]]
  end
  local map = key == 'j' and '<Plug>(accelerated_jk_gj)' or '<Plug>(accelerated_jk_gk)'
  return t(map)
end

_G.enhance_ft_move = function(key)
  if not packer_plugins['vim-eft'].loaded then
    vim.cmd [[packadd vim-eft]]
  end
  local map = {
    f = '<Plug>(eft-f)',
    F = '<Plug>(eft-F)',
    [';'] = '<Plug>(eft-repeat)'
  }
  return t(map[key])
end

_G.enhance_nice_block = function (key)
  if not packer_plugins['vim-niceblock'].loaded then
    vim.cmd [[packadd vim-niceblock]]
  end
  local map = {
    I = '<Plug>(niceblock-I)',
    ['gI'] = '<Plug>(niceblock-gI)',
    A = '<Plug>(niceblock-A)'
  }
  return t(map[key])
end
