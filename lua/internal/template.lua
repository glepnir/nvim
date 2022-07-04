local temp = {}
local api = vim.api
local fn = vim.fn
local home = os.getenv('HOME')
local temp_dir = home .. '/.config/nvim/template/'

--@private
local function get_template(dir)
  return vim.split(fn.globpath(dir,'*'),'\n')
end

--@private
local function get_temp_list()
  local all_temps = vim.split(fn.globpath(temp_dir,'*/*'),'\n')
  local list = {}
  for _,v in pairs(all_temps) do
    v = v:sub(#temp_dir, -1)
    local ft,tp = unpack(vim.split(v,'/',{trimempty = true }))
    if list[ft] == nil then
      list[ft] = {}
    end
    tp = tp:gsub('%.%w+',"")
    table.insert(list[ft],tp)
  end
  return list
end

local keyword = {
  '{{_date_}}','{{_cursor_}}'
}

function temp:generate_template(param)
  local current_buf = api.nvim_get_current_buf()
  local dir = temp_dir .. vim.bo.filetype
  local temps = get_template(dir)
  local index = 0

  for i,file in pairs(temps) do
    if file:find(param) then
      index = i
      break
    end
  end

  local lines = {}
  local cursor_pos = {}
  local date = os.date('%Y-%m-%d %H:%M:%S')
  local lnum = 0

  for line in io.lines(temps[index]) do
    lnum = lnum + 1
    for idx,key in pairs(keyword) do
      if line:find(key) and idx == 1 then
        line = line:gsub(key,date)
      end

      if line:find(key) and idx == 2 then
        line = line:gsub(key,"")
        cursor_pos = { lnum , 2}
      end
    end
    table.insert(lines,line)
  end

  local end_line =  vim.fn.line2byte('$') == -1 and -1 or #lines + 1
  api.nvim_buf_set_lines(current_buf,0,end_line,false,lines)
  api.nvim_win_set_cursor(0,cursor_pos)
  vim.cmd('startinsert!')
end

function temp.genreate_command()
  api.nvim_create_user_command('Template',function(args)
    require('internal.template'):generate_template(args.args)
  end,{
    nargs = '+',
    complete = function(arg)
      local list = get_temp_list()
      return vim.tbl_filter(function (s)
              return string.match(s, "^" .. arg)
            end,list[vim.bo.filetype])
    end
})
end

return temp
