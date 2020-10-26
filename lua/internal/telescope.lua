local global = require('global')
local M = {}

function M.load_dotfiles()
  if not vim.o.runtimepath:find('telescope.nvim') then
    vim.o.runtimepath = vim.o.runtimepath ..','.. global.cache_dir ..'dein/repos/github.com/nvim-lua/telescope.nvim'
    vim.o.runtimepath = vim.o.runtimepath ..','.. global.cache_dir ..'dein/repos/github.com/nvim-lua/popup.nvim'
    vim.o.runtimepath = vim.o.runtimepath ..','.. global.cache_dir ..'dein/repos/github.com/nvim-lua/plenary.nvim'
  end
  local has_telescope,telescope = pcall(require,'telescope.builtin')
  if has_telescope then
    local finders = require('telescope.finders')
    local previewers = require('telescope.previewers')
    local pickers = require('telescope.pickers')
    local sorters = require('telescope.sorters')
    local themes = require('telescope.themes')

    local results = {}
    local dotfiles = os.getenv('HOME')..'/.dotfiles'
    for file in io.popen('find "'..dotfiles..'" -type f'):lines() do
      if not file:find('fonts') then
        table.insert(results,file)
      end
    end

    for file in io.popen('find "'..global.vim_path..'" -type f'):lines() do
      table.insert(results,file)
    end

    telescope.dotfiles = function(opts)
      opts = themes.get_dropdown{}
      pickers.new(opts,{
        prompt = 'dotfiles',
        finder = finders.new_table {
          results = results,
        },
        previewer = previewers.cat.new(opts),
        sorter = sorters.get_generic_fuzzy_sorter(),
      }):find()
    end
  end
  require('telescope.builtin').dotfiles()
end

return M
