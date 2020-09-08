local global = require 'global'
local vim,api = vim,vim.api
local theme = {}
local theme_cache = global.cache_dir..global.path_sep..'theme.txt'

function theme.load_theme()
  local default_theme = 'oceanic_material'
  if vim.g.colors_name == nil then
    api.nvim_set_option('background','dark')
    local scheme = vim.fn.filereadable(theme_cache) and vim.fn.readfile(theme_cache)[1] or default_theme
    api.nvim_command("colorscheme "..scheme)
  end
  api.nvim_command("augroup LoadTheme")
  api.nvim_command("au!")
  api.nvim_command("autocmd ColorScheme * lua require'theme'.write_to_file()")
  api.nvim_command("autocmd ColorSchemePre * lua require'theme'.cleanup_theme()")
  api.nvim_command("augroup END")
end

function theme.write_to_file()
  if vim.g.colors_name ~= nil then
    vim.fn.writefile({vim.g.colors_name},theme_cache)
  end
end

function theme.cleanup_theme()
  if vim.g.colors_name ~= nil then
    return
  end
  vim.api.nvim_command("highlight clear")
end

return theme
