local api = vim.api
local au = api.nvim_create_autocmd
local group = api.nvim_create_augroup('GlepnirGroup', {})

au('TextYankPost', {
  group = group,
  callback = function()
    vim.highlight.on_yank({ higroup = 'IncSearch', timeout = 400 })
  end,
})

au('ExitPre', {
  group = group,
  callback = function()
    if vim.env.TERM == 'alacritty' then
      vim.o.guicursor = 'a:ver90'
    end
  end,
  desc = 'Set cursor back to beam when leaving Neovim.',
})

--disable diagnostic in neovim test file *_spec.lua
au('FileType', {
  group = group,
  pattern = 'lua',
  callback = function(opt)
    local fname = vim.api.nvim_buf_get_name(opt.buf)
    if fname:find('%w_spec%.lua') then
      vim.diagnostic.enable(not vim.diagnostic.is_enabled({ bufnr = opt.buf }))
    end
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
    if vim.bo[args.buf].filetype == 'lua' and api.nvim_buf_get_name(args.buf):find('_spec') then
      vim.diagnostic.enable(false, { bufnr = args.buf })
    end
    if client and client:supports_method('textDocument/documentColor') then
      vim.lsp.document_color.enable(true, args.buf)
    end

    if client then
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

au('BufReadPost', {
  group = group,
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
      require('private.keymap')

      vim.lsp.enable({
        'luals',
        'clangd',
        'rust_analyzer',
        'basedpyright',
        'ruff',
        'zls',
        'cmake',
        'tsls',
      })

      vim.lsp.log.set_level(vim.log.levels.INFO)

      vim.diagnostic.config({
        virtual_text = { current_line = true },
        signs = {
          text = { '●', '●', '●', '●' },
        },
      })

      api.nvim_create_user_command('LspLog', function()
        vim.cmd(string.format('tabnew %s', vim.lsp.get_log_path()))
      end, {
        desc = 'Opens the Nvim LSP client log.',
      })

      require('private.grep')
    end)
  end,
  desc = 'Initializer',
})
