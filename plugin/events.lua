local api = vim.api
local au = api.nvim_create_autocmd
local group = api.nvim_create_augroup('GlepnirGroup', {})

au('TextYankPost', {
  group = group,
  callback = function()
    vim.highlight.on_yank({ higroup = 'IncSearch', timeout = 400 })
  end,
})

au('TermOpen', {
  group = group,
  command = 'setl stc= nonumber | startinsert!',
})

au('LspAttach', {
  group = group,
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client and client.server_capabilities then
      client.server_capabilities.semanticTokensProvider = nil
    end
  end,
})

au('VimEnter', {
  callback = function()
    vim.fn.setreg('"0', '')
  end,
})

au('InsertLeave', {
  group = group,
  callback = function()
    if vim.fn.executable('iswitch') == 0 then
      return
    end

    vim.system({ 'iswitch', '-s', 'com.apple.keylayout.ABC' }, nil, function(proc)
      if proc.code ~= 0 then
        vim.notify('Failed to switch input source: ' .. proc.stderr, vim.log.levels.WARN)
      end
    end)
  end,
  desc = 'auto switch to abc input',
})

au('InsertEnter', {
  group = group,
  once = true,
  callback = function()
    require('private.pairs')
  end,
  desc = 'auto pairs',
})

au('CmdlineEnter', {
  group = group,
  once = true,
  callback = function()
    if vim.version().minor >= 12 then
      require('vim._extui').enable({})
    end
  end,
})

au('UIEnter', {
  group = group,
  once = true,
  callback = function()
    vim.schedule(function()
      require('private.dashboard').show()
      require('private.keymap')

      vim.lsp.enable({
        -- 'luals',
        'emmylua_ls',
        'clangd',
        'rust_analyzer',
        'basedpyright',
        'ruff',
        'zls',
        'cmake',
        'tsls',
      })

      vim.lsp.log.set_level(vim.log.levels.OFF)

      vim.diagnostic.config({
        float = {
          title = '',
          header = '',
        },
        virtual_text = { current_line = true },
        signs = {
          text = { '●', '●', '●', '●' },
          numhl = {
            'DiagnosticError',
            'DiagnosticWarn',
            'DiagnosticInfo',
            'DiagnosticHint',
          },
        },
        severity_sort = true,
      })

      api.nvim_create_user_command('LspLog', function()
        vim.cmd(string.format('tabnew %s', vim.lsp.log.get_filename()))
      end, {
        desc = 'Opens the Nvim LSP client log.',
      })

      api.nvim_create_user_command('LspDebug', function()
        vim.lsp.log.set_level(vim.log.levels.WARN)
      end, { desc = 'enable lsp log' })

      require('private.grep')

      vim.cmd.packadd('nohlsearch')
    end)
  end,
  desc = 'Initializer',
})

au('FileType', {
  pattern = vim.g.language,
  callback = function()
    vim.treesitter.start()
    vim.wo.foldmethod = 'expr'
    vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
    -- vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end,
})
