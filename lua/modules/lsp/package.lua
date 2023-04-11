local function lsp_fts(type)
  type = type or nil
  local fts = {}
  fts.backend = {
    'go',
    'lua',
    'sh',
    'rust',
    'c',
    'cpp',
    'zig',
    'python',
  }

  fts.frontend = {
    'javascript',
    'javascriptreact',
    'typescript',
    'typescriptreact',
    'json',
  }
  if not type then
    return vim.list_extend(fts.backend, fts.frontend)
  end
  return fts[type]
end

local loaded = false
local function diag_config()
  local signs = {
    Error = ' ',
    Warn = ' ',
    Info = ' ',
    Hint = ' ',
  }
  for type, icon in pairs(signs) do
    local hl = 'DiagnosticSign' .. type
    vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
  end

  vim.diagnostic.config({
    signs = true,
    severity_sort = true,
    virtual_text = true,
  })

  --disable diagnostic in neovim test file *_spec.lua
  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'lua',
    callback = function(opt)
      local fname = vim.api.nvim_buf_get_name(opt.buf)
      if fname:find('%w_spec%.lua') then
        vim.diagnostic.disable(opt.buf)
      end
    end,
  })
end

packadd({
  'neovim/nvim-lspconfig',
  dev = true,
  ft = lsp_fts(),
  config = function()
    if not loaded then
      diag_config()
      loaded = true
    end
    require('modules.lsp.backend')
    require('modules.lsp.frontend')
  end,
})

packadd({
  'nvimdev/lspsaga.nvim',
  event = 'LspAttach',
  cmd = 'Lspsaga term_toggle',
  dev = true,
  config = function()
    require('lspsaga').setup({
      symbol_in_winbar = {
        ignore_patterns = { '%w_spec' },
      },
    })
  end,
})
