require 'global'

local theme = {}
local vim =vim

function theme.load_theme()
  local default_theme = 'oceanic_material'
  if vim.g.colors_name ~= nil then
    vim.api.nvim_set_option('background','dark')
    local scheme = vim.fn.filereadable(theme.cache_file) and vim.fn.readfile(theme.cache_file)[1] or default_theme
    local cmd = "silent! exec 'colorscheme'" ..scheme
    vim.api.nvim_command(cmd)
  end
end

function theme.write_to_file()
  theme.cache_file = cache_dir..path_sep..'theme.txt'
  if vim.g.colors_name ~= nil then
    vim.fn.writefile({vim.g.colors_name},theme.cache_file)
  end
end

function theme.cleanup_theme()
  if vim.g.colors_name ~= nil then
    return
  end
  vim.api.nvim_command("highlight clear")
end


function register_theme_event()
  vim.api.nvim_command("augroup LoadTheme")
  vim.api.nvim_command("au!")
  vim.api.nvim_command("autocmd ColorScheme * lua theme.write_to_file()")
  vim.api.nvim_command("autocmd ColorSchemePre * lua theme.cleanup_theme()")
  vim.api.nvim_command("augroup END")
end


