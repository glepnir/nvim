local telescope = require('telescope')
local finders = require('telescope.finders')
local pickers = require('telescope.pickers')
local conf = require('telescope.config').values

local dotfiles_list = function(opts)
  local dir = opts.path or ''
  local list = {}
   local p = io.popen('rg --files '..dir)
   for file in p:lines() do
     if not file:match('.DS_Store') then
      table.insert(list,file)
     end
   end
   return list
end

local dotfiles = function(opts)
  opts = opts or {}
  local results = dotfiles_list(opts)

  pickers.new(opts,{
    prompt_title = 'find in dotfiles',
    results_title = 'Dotfiles',
    finder = finders.new_table {
      results = results
    },
    previewer = conf.file_previewer(opts),
    sorter = conf.file_sorter(opts)
  }):find()
end

return telescope.register_extension { exports = {dotfiles = dotfiles} }
