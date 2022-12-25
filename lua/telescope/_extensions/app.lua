local telescope = require('telescope')
local finders = require('telescope.finders')
local pickers = require('telescope.pickers')
local make_entry = require('telescope.make_entry')
local conf = require('telescope.config').values
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')

-- run mac os applications
local app_list = function()
  local list = vim.split(vim.fn.globpath('/Applications/', '*.app'), '\n')
  return list
end

local app = function(opts)
  opts = opts or {}

  pickers
    .new(opts, {
      prompt_title = 'Search',
      results_title = 'Apps',
      finder = finders.new_table({
        results = app_list(),
        entry_maker = make_entry.gen_from_file(opts),
      }),
      sorter = conf.file_sorter(opts),
      attach_mappings = function(prompt_bufnr, _)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          if selection[1]:find('%s%w+') then
            selection[1] = selection[1]:gsub('%s', '\\ ')
          end
          os.execute('open ' .. selection[1])
        end)
        return true
      end,
    })
    :find()
end

return telescope.register_extension({ exports = { app = app } })
