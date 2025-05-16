local api, uv, fs = vim.api, vim.uv, vim.fs
local strive_path = fs.joinpath(vim.fn.stdpath('data'), 'strive')
vim.g.strive_dev_path = '/Users/mw/workspace'
strive_path = '/Users/mw/workspace/strive'

local installed = (uv.fs_stat(strive_path) or {}).type == 'directory'
async(function()
  if not installed then
    local result =
      try_await(asystem({ 'git', 'clone', 'https://github.com/nvimdev/strive', strive_path }, {
        timeout = 5000,
        stderr = function(_, data)
          if data then
            vim.schedule(function()
              vim.notify(data, vim.log.levels.INFO)
            end)
          end
        end,
      }))

    if not result.success then
      return vim.notify('Failed install strive', vim.log.levels.ERROR)
    end
    vim.notify('Strive installed success', vim.log.levels.INFO)
  end

  vim.o.rtp = strive_path .. ',' .. vim.o.rtp
  local use = require('strive').use

  use('nvimdev/dashboard-nvim')
    :setup({
      theme = 'hyper',
      config = {
        week_header = {
          enable = true,
        },
        project = {
          enable = false,
        },
        disable_move = true,
        shortcut = {
          {
            desc = 'Update',
            group = 'Include',
            action = 'Strive update',
            key = 'u',
          },
          {
            desc = 'Files',
            group = 'Function',
            action = 'FzfLua files',
            key = 'f',
          },
          {
            desc = 'Configs',
            group = 'Constant',
            action = 'FzfLua files cwd=$HOME/.config',
            key = 'd',
          },
        },
      },
    })
    :cond(function()
      return vim.fn.argc() == 0
        and api.nvim_buf_line_count(0) == 0
        and api.nvim_buf_get_name(0) == ''
    end)
    :run('Dashboard')

  use('nvimdev/modeline.nvim'):on({ 'BufEnter */*', 'BufNewFile' }):setup()
  use('lewis6991/gitsigns.nvim'):on({ 'BufEnter */*', 'BufNewFile' }):setup({
    signs = {
      add = { text = '┃' },
      change = { text = '┃' },
      delete = { text = '_' },
      topdelete = { text = '‾' },
      changedelete = { text = '~' },
      untracked = { text = '┃' },
    },
  })
  use('nvimdev/dired.nvim'):cmd('Dired')
  use('nvimdev/indentmini.nvim')
    :on('BufEnter */*')
    :init(function()
      vim.opt.listchars:append({ tab = '  ' })
    end)
    :setup({
      only_current = true,
    })

  use('nvimdev/guard.nvim')
    :on('BufReadPost')
    :config(function()
      local ft = require('guard.filetype')
      ft('c,cpp'):fmt({
        cmd = 'clang-format',
        stdin = true,
        ignore_patterns = { 'neovim', 'vim' },
      })

      ft('lua'):fmt({
        cmd = 'stylua',
        args = { '-' },
        stdin = true,
        ignore_patterns = 'function.*_spec%.lua',
        find = '.stylua.toml',
      })
      ft('rust'):fmt('rustfmt')
      ft('typescript', 'javascript', 'typescriptreact', 'javascriptreact'):fmt('prettier')
    end)
    :depends('nvimdev/guard-collection')

  use('nvimdev/dbsession.nvim'):cmd({ 'SessionSave', 'SessionLoad', 'SessionDelete' })

  use('ibhagwan/fzf-lua'):cmd('FzfLua'):setup({
    'max-perf',
    lsp = { symbols = { symbol_style = 3 } },
  })

  use('nvim-treesitter/nvim-treesitter')
    :on({ 'BufReadPost', 'BufNewFile' })
    :run('TSUpdate')
    :config(function()
      require('nvim-treesitter.configs').setup({
        ensure_installed = {
          'c',
          'cpp',
          'rust',
          'zig',
          'lua',
          'go',
          'python',
          'proto',
          'typescript',
          'javascript',
          'tsx',
          'css',
          'scss',
          'diff',
          'dockerfile',
          'gomod',
          'gosum',
          'gowork',
          'graphql',
          'html',
          'sql',
          'markdown',
          'markdown_inline',
          'json',
          'jsonc',
          'vimdoc',
          'vim',
          'cmake',
        },
        highlight = {
          enable = true,
          disable = function(_, buf)
            local bufname = api.nvim_buf_get_name(buf)
            local max_filesize = 300 * 1024
            local ok, stats = pcall(uv.fs_stat, bufname)
            if ok and stats and stats.size > max_filesize then
              return true
            end
          end,
          additional_vim_regex_highlighting = false,
        },
      })

      vim.schedule(function()
        require('nvim-treesitter.configs').setup({
          textobjects = {
            select = {
              enable = true,
              keymaps = {
                ['af'] = '@function.outer',
                ['if'] = '@function.inner',
                ['ac'] = '@class.outer',
                ['ic'] = { query = '@class.inner' },
              },
            },
          },
        })
      end)
    end)
    :depends('nvim-treesitter/nvim-treesitter-textobjects')

  use('nvimdev/phoenix.nvim'):ft(lang_ft)

  use('nvimdev/lspsaga.nvim')
    :on('LspAttach')
    :setup({
      ui = { use_nerd = false },
      symbol_in_winbar = {
        enable = false,
      },
      lightbulb = {
        enable = false,
      },
      outline = {
        layout = 'float',
      },
    })
    :load_path()
end)()
