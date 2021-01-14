local vim,api = vim,vim.api
local prodoc = {}

local prefix = {
  yaml = '#',
  c  = '//',
  cpp = '//',
  go = '//',
  js = '//',
  ts = '//',
  lua = '--',
  vim = '"',
}

local param = {
  lua = '%((.*)%)',
  go = '%((.*)%)'
}

do
  local _preifx_metatable = {
    __index = function(_,v)
      error(string.format('The current filetype does not support %s',v))
    end
  }

  setmetatable(prefix,_preifx_metatable)
end

local prefix_with_doc = function(pf,params)
  local prefix_doc = {}
  local doc_summary = '@Summary '
  local doc_param = '@Param '

  table.insert(prefix_doc,pf .. ' ' .. doc_summary)
  for _,v in ipairs(params) do
    local p = pf .. ' ' .. doc_param .. ' ' .. v
    table.insert(prefix_doc,p)
  end

  return prefix_doc
end

local _split = function(s,reg)
  local split_table = {}
  for word in s:gmatch(reg) do table.insert(split_table, word) end
  return split_table
end

local generate_line_comment = function(line,lnum,comment_prefix)
  if _split(line,'%S+')[1] == comment_prefix then
    local pre_line = line:gsub(comment_prefix..' ','',1)
    vim.fn.setline(lnum,pre_line)
    return
  end
  vim.fn.setline(lnum,comment_prefix ..' '..line)
end

function prodoc.generate_comment()
  if not vim.bo.modifiable then
    error('Buffer is not modifiable')
    return
  end

  local ft = vim.bo.filetype
  local comment_prefix = prefix[ft]

  local normal_mode = function()
    local pos = vim.fn.getpos('.')
    local line = vim.fn.getline('.')
    generate_line_comment(line,pos[2],comment_prefix)
  end

  local visual_mode = function()
    local vstart = vim.fn.getpos("'<")
    local vend = vim.fn.getpos("'>")
    local line_start,_ = vstart[2],vstart[3]
    local line_end,_ = vend[2],vend[3]
    local lines = vim.fn.getline(line_start,line_end)
    for k,line in ipairs(lines) do
      generate_line_comment(line,line_start+k-1,comment_prefix)
    end
  end

  local _switch = {
    n = normal_mode,
    v = visual_mode,
    V = visual_mode,
  }

  _switch[vim.fn.mode()]()
end

-- generate doc
function prodoc.generate_doc()
  local ft = vim.bo.filetype
  local comment_prefix = prefix[ft]
  local pos = vim.fn.getpos('.')
  local line = vim.fn.getline('.')
  local content = _split(line,param[ft])
  local params = _split(content[1],'[^,%s]+')
  local doc = prefix_with_doc(comment_prefix,params)

  -- insert doc
  vim.fn.append(pos[2]-1,doc)
  -- set curosr
  vim.fn.cursor(pos[2],#doc[1]+#comment_prefix+1)
  -- enter into insert mode
  api.nvim_command('startinsert!')
end

return prodoc
