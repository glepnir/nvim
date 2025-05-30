local api, uv, fs = vim.api, vim.uv, vim.fs
local strive_path = fs.joinpath(vim.fn.stdpath('data'), 'strive.nvim', 'strive')
vim.g.strive_dev_path = '/Users/mw/workspace'

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

  use('nvimdev/modeline.nvim'):on({ 'BufEnter */*', 'BufNewFile' }):setup():load_path()
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
    :load_path()

  use('nvimdev/dbsession.nvim'):cmd({ 'SessionSave', 'SessionLoad', 'SessionDelete' })

  use('ibhagwan/fzf-lua'):cmd('FzfLua'):setup({
    'max-perf',
    lsp = { symbols = { symbol_style = 3 } },
  })

  use('nvim-treesitter/nvim-treesitter')
    :on('StriveDone')
    :branch('main')
    :run(function()
      require('nvim-treesitter').install(vim.g.language)
    end)
    :config(function()
      vim.api.nvim_create_autocmd('FileType', {
        pattern = vim.g.language,
        callback = function()
          vim.treesitter.start()
          vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
          -- vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
      })
    end)
  use('nvim-treesitter/nvim-treesitter-textobjects')
    :on('BufReadPost')
    :branch('main')
    :setup({
      select = {
        -- Automatically jump forward to textobj, similar to targets.vim
        lookahead = true,
        selection_modes = {
          ['@parameter.outer'] = 'v', -- charwise
          ['@function.outer'] = 'V', -- linewise
          ['@class.outer'] = '<c-v>', -- blockwise
        },
        include_surrounding_whitespace = false,
      },
    })
    :config(function()
      vim.keymap.set({ 'x', 'o' }, 'af', function()
        require('nvim-treesitter-textobjects.select').select_textobject(
          '@function.outer',
          'textobjects'
        )
      end)
      vim.keymap.set({ 'x', 'o' }, 'if', function()
        require('nvim-treesitter-textobjects.select').select_textobject(
          '@function.inner',
          'textobjects'
        )
      end)
      vim.keymap.set({ 'x', 'o' }, 'ac', function()
        require('nvim-treesitter-textobjects.select').select_textobject(
          '@class.outer',
          'textobjects'
        )
      end)
      vim.keymap.set({ 'x', 'o' }, 'ic', function()
        require('nvim-treesitter-textobjects.select').select_textobject(
          '@class.inner',
          'textobjects'
        )
      end)
      vim.keymap.set({ 'x', 'o' }, 'as', function()
        require('nvim-treesitter-textobjects.select').select_textobject('@local.scope', 'locals')
      end)
    end)

  use('nvimdev/phoenix.nvim'):ft(vim.g.language)

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
