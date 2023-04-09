local api = vim.api

local function indentline()
  local ns = api.nvim_create_namespace('IndentLine')
  local exclude = { 'dashboard', 'help' }

  local function on_win(_, winid, bufnr, _)
    if bufnr ~= vim.api.nvim_get_current_buf() then
      return false -- FAIL
    end
  end

  local function on_line(_, winid, bufnr, row)
    local indent = vim.fn.indent(row + 1)
    for i = 1, indent - 1, 2 do
      api.nvim_buf_set_extmark(bufnr, ns, row, i - 1, {
        virt_text = { { '│', 'Comment' } },
        virt_text_pos = 'overlay',
        ephemeral = true,
      })
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
