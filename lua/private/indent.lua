local api = vim.api

local ns = api.nvim_create_namespace('indent')
local char = '┆'
local hl = 'NonText'

local augroup = vim.api.nvim_create_augroup('indentlines', {})

local function guides(sw)
  if sw == 0 then
    sw = vim.bo.tabstop
  end
  local indent_char = '┆' .. (' '):rep(sw - 1)
  vim.opt_local.listchars:append({ leadmultispace = indent_char })
end

vim.api.nvim_create_autocmd('OptionSet', {
  pattern = { 'shiftwidth', 'tabstop', 'expandtab' },
  group = augroup,
  callback = function()
    guides(vim.v.option_new)
  end,
})

vim.api.nvim_create_autocmd('BufWinEnter', {
  group = augroup,
  callback = function(args)
    guides(vim.bo[args.buf].shiftwidth)
  end,
})

local function is_blank(line)
  return line == '' or not line:find('[^ \t]')
end

local function get_step(bufnr)
  local sw = vim.bo[bufnr].shiftwidth
  if sw == 0 then
    sw = vim.bo[bufnr].tabstop
  end
  return sw
end

local function indent_cols(line, tabstop)
  local col = 0
  for i = 1, #line do
    local b = line:byte(i)
    if b == 32 then
      col = col + 1
    elseif b == 9 then
      col = col + (tabstop - (col % tabstop))
    else
      break
    end
  end
  return col
end

local function infer_blank_indent(bufnr, lnum, tabstop)
  local prev = lnum - 1
  while prev >= 1 do
    local pline = api.nvim_buf_get_lines(bufnr, prev - 1, prev, false)[1] or ''
    if not is_blank(pline) then
      return indent_cols(pline, tabstop)
    end
    prev = prev - 1
  end
  return 0
end

api.nvim_set_decoration_provider(ns, {
  on_win = function(_, winid, bufnr, _, _)
    local step = get_step(bufnr)
    local tabstop = vim.bo[bufnr].tabstop
    local leftcol = vim.fn.winsaveview().leftcol

    vim.w[winid].__indent_blank_ctx = {
      step = step,
      tabstop = tabstop,
      leftcol = leftcol,
    }
  end,

  on_line = function(_, winid, bufnr, row)
    local ctx = vim.w[winid].__indent_blank_ctx
    if not ctx then
      return
    end

    local lnum = row + 1
    local line = api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ''
    if not is_blank(line) then
      return
    end

    local indent = infer_blank_indent(bufnr, lnum, ctx.tabstop)
    if indent <= 0 then
      return
    end

    local step = ctx.step > 0 and ctx.step or ctx.tabstop
    if step <= 0 then
      return
    end

    local levels = math.floor(indent / step)
    for level = 1, levels do
      local col = (level - 1) * step
      if col >= ctx.leftcol then
        api.nvim_buf_set_extmark(bufnr, ns, row, col, {
          virt_text = { { char, hl } },
          virt_text_pos = 'overlay',
          hl_mode = 'combine',
          ephemeral = true,
          virt_text_win_col = col - ctx.leftcol,
        })
      end
    end
  end,
})
