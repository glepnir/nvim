local telescope = require('telescope')
local finders = require('telescope.finders')
local pickers = require('telescope.pickers')
local make_entry = require('telescope.make_entry')
local conf = require('telescope.config').values
local os_name = vim.loop.os_uname().sysname
local fn = vim.fn

local golang_source = function()
  local root
  local result = {}
  if os_name == 'Darwin' then
    if vim.fn.isdirectory('/usr/local/go') then
      root = '/usr/local/go/src/'
    else
      root = fn.globpath('/usr/local/Cellar/go', '*') .. '/libexec/src/'
    end
  end
  local dicts = fn.split(fn.globpath(root, '*'))

  for _, dict in pairs(dicts) do
    local f = fn.split(fn.globpath(dict, '*.go'))
    if next(f) ~= nil then
      for _, val in pairs(f) do
        table.insert(result, val)
      end
    end
  end
  return result
end

local gosource = function(opts)
  opts = opts or {}
  local results = golang_source()

  pickers
    .new(opts, {
      prompt_title = 'Find In Go Root',
      results_title = 'Go Source Code',
      finder = finders.new_table({
        results = results,
        entry_maker = make_entry.gen_from_file(opts),
      }),
      previewer = conf.file_previewer(opts),
      sorter = conf.file_sorter(opts),
    })
    :find()
end

return telescope.register_extension({ exports = { gosource = gosource } })
