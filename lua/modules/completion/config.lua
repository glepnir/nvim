local config = {}

function config.nvim_lsp()
  require('modules.completion.lspconfig')
end

function config.lspsaga()
  require('lspsaga').setup({})
end

function config.lua_snip()
  local ls = require('luasnip')
  ls.config.set_config({
    delete_check_events = 'TextChanged,InsertEnter',
  })
  require('luasnip.loaders.from_vscode').lazy_load({
    paths = { './snippets/' },
  })
end

function config.auto_pairs()
  require('nvim-autopairs').setup({})
end

return config
