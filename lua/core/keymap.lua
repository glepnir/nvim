local keymap = {}
local opts = {}

function opts:new(instance)
  instance = instance or {
    options = {
      silent = false,
      nowait = false,
      expr = false,
      noremap = false
    }
  }
  setmetatable(instance,self)
  self.__index = self
  return instance
end

function keymap.silent(opt)
  return function()
    opt.silent = true
  end
end

function keymap.noremap(opt)
  return function()
    opt.noremap = true
  end
end

function keymap.expr(opt)
  return function()
    opt.expr = true
  end
end

function keymap.remap(opt)
  return function()
    opt.remap = true
  end
end

function keymap.nowait(opt)
  return function()
    opt.nowait = true
  end
end

function keymap.new_opts(...)
  local args = { ... }
  local o = opts:new()

  if #args == 0 then
    return o.options
  end

  for _,arg in pairs(args) do
    arg(o.options)()
  end
  return o.options
end

function keymap.cmd(str)
  return '<cmd>' .. str .. '<CR>'
end

-- visual
function keymap.cu(str)
  return '<C-u><cmd>' .. str .. '<CR>'
end

--@private
local keymap_set = function(tbl)
  vim.validate {
    tbl = {tbl,'table'}
  }
  local len = #tbl
  if len < 3 then
    vim.notify('keymap must has rhs')
    return
  end

  local options = len == 4 and tbl[4] or keymap.new_opts()

  vim.keymap.set(tbl[1],tbl[2],tbl[3],options)
end

function keymap.map(tbl)
  vim.validate {
    tbl = { tbl,'table' }
  }

  if type(tbl[1]) == 'table' and type(tbl[2]) == 'table' then
    for _,v in pairs(tbl) do
      keymap_set(v)
    end
  else
    keymap_set(tbl)
  end
end

return keymap
