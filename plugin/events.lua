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
    require('internal.keymap')
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

au('LspAttach', {
  callback = function(args)
    if vim.bo[args.buf].filetype == 'lua' and api.nvim_buf_get_name(args.buf):find('_spec') then
      vim.diagnostic.enable(false, { bufnr = args.buf })
    end

    local client = vim.lsp.get_clients({ id = args.data.client_id })[1]
    client.server_capabilities.semanticTokensProvider = nil
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
    if not client or not vim.tbl_isempty(client.attached_buffers) then
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

au('CmdlineLeave', {
  group = group,
  once = true,
  callback = function()
    if vim.v.event.cmdtype ~= '/' then
      return
    end
    au({ 'InsertEnter', 'CursorHold' }, {
      group = group,
      callback = function()
        if vim.v.hlsearch == 0 then
          return
        end
        local keycode = api.nvim_replace_termcodes('<Cmd>nohl<CR>', true, false, true)
        api.nvim_feedkeys(keycode, 'n', false)
      end,
    })
  end,
})
