local api = vim.api
local au = api.nvim_create_autocmd
local group = api.nvim_create_augroup('GlepnirGroup', {})

au('TextYankPost', {
  group = group,
  callback = function()
    vim.hl.on_yank({ higroup = 'IncSearch', timeout = 400 })
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

local function startuptime()
  if vim.g.strive_startup_time ~= nil then
    return
  end
  vim.g.strive_startup_time = 0
  local usage = vim.uv.getrusage()
  if usage then
    -- Calculate time in milliseconds (user + system time)
    local user_time = (usage.utime.sec * 1000) + (usage.utime.usec / 1000)
    local sys_time = (usage.stime.sec * 1000) + (usage.stime.usec / 1000)
    vim.g.nvim_startup_time = user_time + sys_time
  end
end

vim.lsp.enable({
  'luals',
  -- 'emmylua_ls',
  'clangd',
  'rust_analyzer',
  'basedpyright',
  'ruff',
  'zls',
  'cmake',
  'tsls',
})

au('UIEnter', {
  group = group,
  once = true,
  callback = function()
    startuptime()
    vim.schedule(function()
      require('private.dashboard').show()
      require('private.keymap')

      vim.lsp.log.set_level(vim.log.levels.OFF)
      vim.diagnostic.config({
        float = true,
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

      if vim.version().minor >= 12 then
        require('private.grep')
      end
      require('private.compile')

      vim.cmd.packadd('nohlsearch')
      vim.cmd.packadd('nvim.undotree')
    end)
  end,
  desc = 'Initializer',
})

au('FileType', {
  group = group,
  callback = function(opts)
    local lang = vim.treesitter.language.get_lang(vim.bo[opts.buf].filetype)
    if vim.treesitter.language.add(lang) then
      vim.treesitter.start(opts.buf, lang)
      vim.wo[0][0].foldmethod = 'expr'
      vim.wo[0][0].foldexpr = 'v:lua.vim.treesitter.foldexpr()'
    end
  end,
  desc = 'try start treesitter highlight',
})
