local uv = vim.uv
local strive = vim.fs.joinpath(vim.fn.stdpath('data'), 'site', 'pack', 'strive', 'opt', 'strive')
vim.g.strive_dev_path = '/Users/mw/workspace'

local installed = (uv.fs_stat(strive) or {}).type == 'directory'
async(function()
  if not installed then
    local result =
      try_await(asystem({ 'git', 'clone', 'https://github.com/nvimdev/strive', strive }, {
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

  vim.o.rtp = strive .. ',' .. vim.o.rtp
  local use = require('strive').use

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
        args = function(bufnr)
          local f = vim.bo[bufnr].filetype == 'cpp' and '.cpp.clang-format' or '.clang-format'
          return { ('--style=file:%s/%s'):format(vim.env.HOME, f) }
        end,
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

  use('nvim-treesitter/nvim-treesitter'):on('BufReadPre'):branch('main'):run(function()
    require('nvim-treesitter').install(vim.g.language)
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

  use('nvimdev/phoenix.nvim'):ft(vim.g.language):init(function()
    vim.g.phoenix = {
      snippet = vim.fn.stdpath('config') .. '/snippets',
    }
  end)

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

  use('nvimdev/visualizer.nvim'):cmd({
    'VisualizerFull',
    'VisualizerIncoming',
    'VisualizerOutgoing',
  })
end)()
