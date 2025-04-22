local api, uv = vim.api, vim.uv
local data_dir = vim.fn.stdpath('data')
local strive_path = vim.fs.joinpath(data_dir, 'site', 'pack', 'strive', 'opt', 'strive')
local devpath = '/Users/mw/workspace'

async(function()
  local installed = (uv.fs_stat(strive_path) or {}).type == 'directory'
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

  use('nvimdev/dashboard-nvim'):setup({
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
          action = 'Lazy update',
          key = 'u',
        },
        {
          desc = 'Files',
          group = 'Function',
          action = 'FzfLua files',
          key = 'f',
        },
        {
          desc = 'Apps',
          group = 'String',
          action = 'Telescope app',
          key = 'a',
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

  use('nvimdev/modeline.nvim'):on({ 'BufEnter', 'BufNewFile' }):setup()
  use('lewis6991/gitsigns.nvim'):on('BufEnter'):setup({
    signs = {
      add = { text = '┃' },
      change = { text = '┃' },
      delete = { text = '_' },
      topdelete = { text = '‾' },
      changedelete = { text = '~' },
      untracked = { text = '┃' },
    },
  })
  use('nvimdev/dired.nvim'):cmd('Dired'):load_path(devpath)
  use('nvimdev/indentmini.nvim')
    :on('BufEnter */*')
    :init(function()
      vim.opt.listchars:append({ tab = '  ' })
    end)
    :setup({
      only_current = true,
    })

  use('nvimdev/guard.nvim')
    :ft(program_ft)
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

  use('nvimdev/fnpairs.nvim'):on('InsertEnter'):setup()
  use('nvimdev/dbsession.nvim'):cmd({ 'SessionSave', 'SessionLoad', 'SessionDelete' })

  use('ibhagwan/fzf-lua'):cmd('FzfLua'):setup({
    'max-perf',
  })

  use('nvim-treesitter/nvim-treesitter')
    :on({ 'BufRead', 'BufNewFile' })
    :build('TSUpdate')
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
            local bufname = vim.api.nvim_buf_get_name(buf)
            local max_filesize = 300 * 1024
            local ok, stats = pcall(uv.fs_stat, bufname)
            if ok and stats and stats.size > max_filesize then
              return true
            end
          end,
          additional_vim_regex_highlighting = false,
        },
      })

      vim.api.nvim_create_autocmd('FileType', {
        callback = function(args)
          local ok = pcall(vim.treesitter.get_parser, args.buf)
          if ok and vim.wo.foldmethod ~= 'expr' then
            vim.wo.foldmethod = 'expr'
            vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
            vim.defer_fn(function()
              vim.cmd('normal! zx')
            end, 50)
          end
        end,
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

  use('nvimdev/phoenix.nvim'):ft(program_ft)
  use('neovim/nvim-lspconfig'):ft(program_ft)

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
    :load_path(devpath)
end)()

local i = '●'
vim.diagnostic.config({
  virtual_text = { current_line = true },
  signs = {
    text = { i, i, i, i },
  },
})

api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local client = vim.lsp.get_clients({ id = args.data.client_id })[1]
    client.server_capabilities.semanticTokensProvider = nil
  end,
})

vim.lsp.config('lua_ls', {
  on_init = function(client)
    if client.workspace_folders then
      local path = client.workspace_folders[1].name
      if
        path ~= vim.fn.stdpath('config')
        and (vim.loop.fs_stat(path .. '/.luarc.json') or vim.loop.fs_stat(path .. '/.luarc.jsonc'))
      then
        return
      end
    end

    client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
      runtime = {
        version = 'LuaJIT',
      },
      workspace = {
        checkThirdParty = false,
        library = {
          vim.env.VIMRUNTIME,
        },
      },
    })
  end,
  settings = {
    Lua = {},
  },
})

vim.lsp.config('clangd', {
  cmd = { 'clangd', '--background-index', '--header-insertion=never' },
  init_options = { fallbackFlags = { vim.bo.filetype == 'cpp' and '-std=c++23' or nil } },
})

vim.lsp.config('rust_analyzer', {
  settings = {
    ['rust-analyzer'] = {
      imports = {
        granularity = {
          group = 'module',
        },
        prefix = 'self',
      },
      cargo = {
        buildScripts = {
          enable = true,
        },
      },
      procMacro = {
        enable = true,
      },
    },
  },
})

vim.lsp.enable({
  'lua_ls',
  'clangd',
  'rust_analyzer',
  'basedpyright',
  'ruff',
  'bashls',
  'zls',
  'cmake',
  'jsonls',
  'ts_ls',
  'eslint',
  'tailwindcss',
  'cssls',
})
