local api, lsp, uv = vim.api, vim.lsp, vim.uv
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
  end,
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

--for alacritty only
au('ExitPre', {
  group = group,
  command = 'set guicursor=a:ver90',
  desc = 'Set cursor back to beam when leaving Neovim.',
})

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
    map('s', split('vsplit'), false, 'vsplit open')
    map('v', split('split'), false, 'split open')
  end,
})

--- @table<integer, uv_timer_t> Timers indexed by LSP client ID
local detach_client_timers = {}

au('LspDetach', {
  callback = function(args)
    local client_id = args.data.client_id
    local attached_buffers = lsp.get_buffers_by_client_id(client_id)
    if #attached_buffers > 0 then
      return
    end
    local timer = assert(uv.new_timer()) --[uv_timer_t]
    timer:start(
      5000,
      0,
      vim.schedule_wrap(function()
        local name = lsp.get_client_by_id(client_id).name
        lsp.stop_client(client_id, true)
        print(('client id %d name %s is closed'):format(client_id, name))
      end)
    )
    detach_client_timers[client_id] = timer
  end,
  desc = '[glepnir]Timer on closing client',
})

au('LspAttach', {
  callback = function(args)
    local client_id = args.data.client_id
    if detach_client_timers[client_id] then
      local timer = detach_client_timers[client_id]
      if timer:is_active() and not timer:closing() then
        timer:stop()
        timer:close()
      end
    end
    detach_client_timers[client_id] = nil
  end,
  desc = '[glepnir] Canceld closing client',
})
