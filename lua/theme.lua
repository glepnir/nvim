require 'global'
local vim = vim

theme_cache = cache_dir..path_sep..'theme.txt'

function load_theme()
  local default_theme = 'oceanic_material'
  if vim.g.colors_name == nil then
    vim.api.nvim_set_option('background','dark')
    local scheme = vim.fn.filereadable(theme_cache) and vim.fn.readfile(theme_cache)[1] or default_theme
    vim.api.nvim_command("colorscheme "..scheme)
  end
end

function write_to_file()
  if vim.g.colors_name ~= nil then
    vim.fn.writefile({vim.g.colors_name},theme_cache)
  end
end

function cleanup_theme()
  if vim.g.colors_name ~= nil then
    return
  end
  vim.api.nvim_command("highlight clear")
end

function register_theme_event()
  vim.api.nvim_command("augroup LoadTheme")
  vim.api.nvim_command("au!")
  vim.api.nvim_command("autocmd ColorScheme * lua write_to_file()")
  vim.api.nvim_command("autocmd ColorSchemePre * lua cleanup_theme()")
  vim.api.nvim_command("augroup END")
end
