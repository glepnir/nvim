local config = {}

local function load_env_file()
  local env_file = vim.env.HOME .. '/.env'
  local env_contents = {}
  if vim.fn.filereadable(env_file) ~= 1 then
    print('.env file does not exist')
    return
  end
  local contents = vim.fn.readfile(env_file)
  for _, item in pairs(contents) do
    local line_content = vim.fn.split(item, '=')
    env_contents[line_content[1]] = line_content[2]
  end
  return env_contents
end

local function load_dbs()
  local env_contents = load_env_file()
  local dbs = {}
  for key, value in pairs(env_contents or {}) do
    if vim.fn.stridx(key, 'DB_CONNECTION_') >= 0 then
      local db_name = vim.fn.split(key, '_')[3]:lower()
      dbs[db_name] = value
    end
  end
  return dbs
end

function config.vim_dadbod_ui()
  vim.g.db_ui_show_help = 0
  vim.g.db_ui_win_position = 'left'
  vim.g.db_ui_use_nerd_fonts = 1
  vim.g.db_ui_winwidth = 35
  vim.g.db_ui_save_location = vim.env.HOME .. '/.cache/vim/db_ui_queries'
  vim.g.dbs = load_dbs()
end

function config.template_nvim()
  require('template').setup({
    temp_dir = '~/.config/nvim/template',
    author = 'glepnir',
    email = 'glephunter@gmail.com',
  })
  require('telescope').load_extension('find_template')
end

function config.easyformat()
  require('easyformat').setup({
    fmt_on_save = true,
    c = {
      cmd = 'clang-format',
      args = { '-style=file', vim.api.nvim_buf_get_name(0) },
      pattern = { 'neovim/*' },
      find = '.clang-format',
      stdin = false,
      lsp = false,
    },
    cpp = {
      cmd = 'clang-format',
      args = { '-style=file', vim.api.nvim_buf_get_name(0) },
      find = '.clang-format',
      stdin = false,
      lsp = false,
    },
    go = {
      cmd = 'golines',
      args = { '--max-len=80', vim.api.nvim_buf_get_name(0) },
      stdin = false,
      hook = function()
        vim.lsp.buf.code_action({ context = { only = { 'source.organizeImports' } }, apply = true })
      end,
      lsp = true,
    },
    lua = {
      cmd = 'stylua',
      ignore_patterns = { '%pspec', 'neovim/*' },
      find = '.stylua.toml',
      args = { '-' },
      stdin = true,
      lsp = false,
    },
  })
end

return config
