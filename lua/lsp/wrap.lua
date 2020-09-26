local M = {}

function M.wrap_line(text,width)
  local line = ''
  local ret = {}
  local content = vim.fn.split(text)
  for idx,word in pairs(content) do

    if #line + #word + 1 > width then
      if #word > 3 then
        local pos = width-#line-3
        line = line .. word:sub(1,pos)
        table.insert(ret,line)
        line = word:sub(pos+1,#word)
        if idx == #content then
          table.insert(ret,line)
        end
      else
        table.insert(ret,line)
        line = ''
      end
    end

    line = line ..word .. ' '
  end

  return ret
end

function M.add_truncate_line(contents)
  local line_widths = {}
  local width = 0
  local truncate_line = '─'

  for i,line in ipairs(contents) do
    line_widths[i] = vim.fn.strdisplaywidth(line)
    width = math.max(line_widths[i], width)
  end

  for _=1,width,1 do
    truncate_line = truncate_line .. '─'
  end

  return truncate_line
end

return M

