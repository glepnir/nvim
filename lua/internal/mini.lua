local api = vim.api
local ctx = {}

local function indentline()
  local ns = api.nvim_create_namespace('IndentLine')
  local exclude = { 'dashboard', 'help' }

  local function on_win(_, _, bufnr, _)
    if bufnr ~= vim.api.nvim_get_current_buf() then
      return false -- FAIL
    end
  end

  local function on_line(_, _, bufnr, row)
    local indent = vim.fn.indent(row + 1)
    local text = api.nvim_buf_get_text(bufnr, row, 0, row, -1, {})[1]

    if indent == 0 and #text == 0 then
      local prev = vim.fn.indent(row)
      if prev > 0 then
        indent = prev
        if not ctx[bufnr] then
          ctx[tostring(bufnr)] = {}
        end
        ctx[tostring(bufnr)][tostring(row + 1)] = indent
      elseif ctx[tostring(bufnr)][tostring(row)] then
        indent = ctx[tostring(bufnr)][tostring(row)]
      end
    end

    for i = 1, indent - 1, 2 do
      api.nvim_buf_set_extmark(bufnr, ns, row, i - 1, {
        id = row,
        virt_text = { { '│', 'IndentLine' } },
        virt_text_pos = 'overlay',
        ephemeral = true,
      })
    end

    if row + 1 == api.nvim_buf_line_count(bufnr) then
      ctx[tostring(bufnr)] = nil
    end
  end

  local function on_start(_, _)
    local bufnr = api.nvim_get_current_buf()
    if vim.tbl_contains(exclude, vim.bo[bufnr].ft) then
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
