local api = vim.api
local treesitter = vim.treesitter
local ctx = {}

local function check_inblock()
  local type = {
    'block',
    'compound_statement',
    'preproc_def',
    'case_statement',
    'if_statement',
    'while_statement',
    'argument_list',
  }
  return function(bufnr, row)
    local node = treesitter.get_node({ bufnr = bufnr, pos = { row, 0 } })
    if node and vim.tbl_contains(type, node:type()) then
      return true
    end
    return false
  end
end

local function indentline()
  local ns = api.nvim_create_namespace('IndentLine')
  local exclude = { 'dashboard', 'lazy', 'help', 'markdown' }

  local function on_win(_, _, bufnr, _)
    if bufnr ~= vim.api.nvim_get_current_buf() then
      return false
    end
  end

  local function on_line(_, _, bufnr, row)
    local indent = vim.fn.indent(row + 1)
    local text = api.nvim_buf_get_text(bufnr, row, 0, row, -1, {})[1]
    local inblock = check_inblock()
    ctx[#ctx + 1] = indent

    if indent == 0 and #text == 0 and inblock(bufnr, row) then
      local prev
      for i = 1, 4 do
        if #ctx - i > 0 and ctx[#ctx - i] > 0 then
          prev = ctx[#ctx - i]
          ctx[#ctx] = prev
          break
        end
      end

      if not prev then
        indent = 0
      else
        indent = prev > 20 and 4 or prev
      end
    end

    for i = 1, indent - 1, vim.bo[bufnr].sw do
      local pos = 'overlay'
      local symbol = '│'
      if #text == 0 and i - 1 > 0 then
        pos = 'eol'
        symbol = (i == 1 + vim.bo[bufnr].sw and (' '):rep(vim.bo[bufnr].sw - 1) or '') .. '│'
      end

      api.nvim_buf_set_extmark(bufnr, ns, row, i - 1, {
        virt_text = { { symbol, 'IndentLine' } },
        virt_text_pos = pos,
        ephemeral = true,
      })
    end

    if row + 1 == vim.fn.line('w$') then
      ctx = {}
    end
  end

  local function on_start(_, _)
    local bufnr = api.nvim_get_current_buf()
    if
      vim.bo[bufnr].buftype == 'nofile'
      or not vim.bo[bufnr].expandtab
      or vim.tbl_contains(exclude, vim.bo[bufnr].ft)
    then
      return false
    end
  end

  api.nvim_set_decoration_provider(ns, {
    on_win = on_win,
    on_start = on_start,
    on_line = on_line,
  })
end

return {
  indentline = indentline,
}
