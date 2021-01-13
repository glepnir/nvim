local vim,api = vim,vim.api
local prodoc = {}

local prefix = {
  go = '//',
  lua = '--'
}

do
  local _preifx_metatable = {
    __index = function(_,v)
      error(string.format('The current filetype does not support %s',v))
    end
  }

  setmetatable(prefix,_preifx_metatable)
end

local prefix_with_doc = function(pf)
  local prefix_doc = {}
  local doc = {
    '@Summary ',
    '@Param '
  }

  for _,v in ipairs(doc) do
    table.insert(prefix_doc,pf .. ' ' .. v)
  end

  return prefix_doc
end

-- TODO: support visual mode
function prodoc.generate_comment()
  local mode = vim.fn.mode()
  local ft = vim.bo.filetype
  local comment_prefix = prefix[ft]
  if mode == 'n' then
    local pos = vim.fn.getpos('.')
    local line = vim.fn.getline('.')

    if line:match('^'..comment_prefix) then
      local pre_line = line:gsub('//','',1)
      vim.fn.setline(pos[2],pre_line)
      return
    end
    vim.fn.setline(pos[2],comment_prefix ..' '..line)
  end
end

-- generate doc
function prodoc.generate_doc()
  local ft = vim.bo.filetype
  local comment_prefix = prefix[ft]
  local doc = prefix_with_doc(comment_prefix)
  local pos = vim.fn.getpos('.')

  -- insert doc
  vim.fn.append(pos[2]-1,doc)
  -- set curosr
  vim.fn.cursor(pos[2],#doc[1]+#comment_prefix+1)
  -- enter into insert mode
  api.nvim_command('startinsert!')
end

return prodoc
