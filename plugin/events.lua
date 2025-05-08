local api = vim.api
local au = api.nvim_create_autocmd
local group = api.nvim_create_augroup('GlepnirGroup', {})

au('BufWritePre', {
  group = group,
  pattern = { '/tmp/*', 'COMMIT_EDITMSG', 'MERGE_MSG', '*.tmp', '*.bak' },
  command = 'setlocal noundofile',
})

au('TextYankPost', {
  group = group,
  callback = function()
    vim.highlight.on_yank({ higroup = 'IncSearch', timeout = 400 })
  end,
})

au('BufEnter', {
  group = group,
  once = true,
  callback = function()
    require('private.keymap')
  end,
  desc = 'Lazy load my keymap and buffer relate commands and defaul opt plugins',
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
    if vim.bo[args.buf].filetype == 'lua' and api.nvim_buf_get_name(args.buf):find('_spec') then
      vim.diagnostic.enable(false, { bufnr = args.buf })
    end

    vim.iter(vim.lsp.get_clients({ id = args.data.client_id })):map(function(client)
      client.server_capabilities.semanticTokensProvider = nil
    end)
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

au('FileType', {
  pattern = program_ft,
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
  callback = function()
    require('private.pairs')
  end,
  desc = 'auto pairs',
})

au('CmdlineEnter', {
  group = group,
  callback = function()
    require('private.grep')
  end,
})
