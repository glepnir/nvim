local api = vim.api
local au = api.nvim_create_autocmd
local group = vim.api.nvim_create_augroup('GlepnirGroup', {})

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
    require('keymap')
    require('internal.buffer')
    vim.cmd.packadd('nohlsearch')
  end,
  desc = 'Lazy load my keymap and buffer relate commands and defaul opt plugins',
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

if vim.env.TERM == 'alacritty' then
  au('ExitPre', {
    group = group,
    command = 'set guicursor=a:ver90',
    desc = 'Set cursor back to beam when leaving Neovim.',
  })
end

au('TermOpen', {
  group = group,
  callback = function()
    vim.opt_local.stc = ''
    vim.wo.number = false
    vim.cmd.startinsert()
  end,
})

au('InsertEnter', {
  group = group,
  callback = function()
    require('internal.pairs').setup({})
  end,
})

au('LspAttach', {
  callback = function(args)
    if vim.bo[args.buf].filetype == 'lua' and api.nvim_buf_get_name(args.buf):find('_spec') then
      vim.diagnostic.enable(false, { bufnr = args.buf })
    end
  end,
})

local timer = nil --[[uv_timer_t]]
local function reset_timer()
  if timer then
    timer:stop()
    timer:close()
  end
  timer = nil
end

au('VimEnter', {
  callback = function()
    vim.fn.setreg('"0', '')
  end,
})

au('LspDetach', {
  callback = function(args)
    local client_id = args.data.client_id
    local client = vim.lsp.get_clients({ client_id = client_id })[1]
    if not vim.tbl_isempty(client.attached_buffers) then
      return
    end
    reset_timer()
    timer = assert(vim.uv.new_timer())
    timer:start(200, 0, function()
      reset_timer()
      vim.schedule(function()
        vim.lsp.stop_client(client_id, true)
      end)
    end)
  end,
  desc = 'Auto stop client when no buffer atttached',
})

au('InsertLeave', {
  callback = function()
    if vim.fn.executable('iswitch') == 0 then
      return
    end
    vim.system({ 'iswitch', '-s', 'com.apple.keylayout.ABC' }, nil, function(proc)
      if proc.code ~= 0 then
        api.nvim_err_writeln('Failed to switch input source: ' .. proc.stderr)
      end
    end)
  end,
  desc = 'auto switch to abc input',
})

au('FileType', {
  pattern = 'netrw',
  callback = function()
    local map = function(lhs, rhs, remap, desc)
      vim.keymap.set('n', lhs, rhs, { buffer = true, remap = remap, desc = desc })
    end
    vim.wo.stc = ''
    local function split(cmd)
      return function()
        vim.cmd(('%s %s'):format(cmd, vim.fn.expand('<cfile>')))
      end
    end
    map('r', 'R', true, 'rename file')
    map('l', '<CR>', true, 'open directory or file')
    map('.', 'gh', true, 'toggle dotfiles')
    map('H', 'u', true, 'go back')
    map('h', '-^', true, 'go up')
    map('c', '%', true, 'create file')
    map('s', split('vsplit'), false, 'vsplit open')
    map('v', split('split'), false, 'split open')
    map('<C-l>', '<C-W>l', false)
  end,
})
