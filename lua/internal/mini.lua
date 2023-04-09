local api = vim.api
local ctx = {}

local function indentline()
  local ns = api.nvim_create_namespace('IndentLine')
  local exclude = { 'dashboard', 'lazy', 'help' }

  local function on_win(_, _, bufnr, _)
    if bufnr ~= vim.api.nvim_get_current_buf() then
      return false
    end
  end

  local function on_line(_, _, bufnr, row)
    local indent = vim.fn.indent(row + 1)
    local text = api.nvim_buf_get_text(bufnr, row, 0, row, -1, {})[1]

    if indent == 0 and #text == 0 then
      local prev = vim.fn.indent(row)
      if prev > 0 then
        local p_prev = vim.fn.indent(row - 1)
        --this for some wrap indent like
        --int xxx = xxxxxxxxxxxxxxxxxxxxxxxx ? xxx
        --                                   : xxx
        --in this situation use pprev indent
        indent = prev - p_prev > 4 and 4 or prev
        if not ctx[bufnr] then
          ctx[bufnr] = {}
        end
        ctx[bufnr][row + 1] = indent
      elseif ctx[bufnr] and ctx[bufnr][row] then
        indent = ctx[bufnr][row]
      end
    end

    for i = 1, indent - 1, vim.bo[bufnr].sw do
      local pos = 'overlay'
      local symbol = '│'
      if #text == 0 and i - 1 > 0 then
        pos = 'eol'
        symbol = (bit.band((i - 1) * 0.5, 1) == 1 and ' ' or '') .. '│'
      end

      api.nvim_buf_set_extmark(bufnr, ns, row, i - 1, {
        virt_text = { { symbol, 'IndentLine' } },
        virt_text_pos = pos,
        ephemeral = true,
      })
    end

    if row + 1 == api.nvim_buf_line_count(bufnr) then
      ctx[bufnr] = nil
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
