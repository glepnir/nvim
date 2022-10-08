local telescope = require('telescope')
local finders = require('telescope.finders')
local pickers = require('telescope.pickers')
local make_entry = require('telescope.make_entry')
local conf = require('telescope.config').values

local dot_path = vim.env.HOME .. '/.dotfiles,' .. vim.env.HOME .. '/.config/nvim'

local dotfiles_list = function()
  local dirs = vim.split(dot_path, ',')
  local list = {}
  for _, dir in pairs(dirs) do
    local p = io.popen('rg --files --hidden ' .. dir)
    for file in p:lines() do
      table.insert(list, file)
    end
  end
  return list
end

local dotfiles = function(opts)
  opts = opts or {}
  local results = dotfiles_list()

  pickers
    .new(opts, {
      prompt_title = 'find in dotfiles',
      results_title = 'Dotfiles',
      finder = finders.new_table({
        results = results,
        entry_maker = make_entry.gen_from_file(opts),
      }),
      previewer = conf.file_previewer(opts),
      sorter = conf.file_sorter(opts),
    })
    :find()
end

return telescope.register_extension({ exports = { dotfiles = dotfiles } })
