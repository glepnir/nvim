local config = {}

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
  require('nvim-autopairs').setup({
    map_cr = false,
  })
end

function config.telescope()
  local fb_actions = require('telescope').extensions.file_browser.actions
  require('telescope').setup({
    defaults = {
      prompt_prefix = ' ',
      selection_caret = ' ',
      layout_config = {
        horizontal = { prompt_position = 'top', results_width = 0.6 },
        vertical = { mirror = false },
      },
      sorting_strategy = 'ascending',
      file_previewer = require('telescope.previewers').vim_buffer_cat.new,
      grep_previewer = require('telescope.previewers').vim_buffer_vimgrep.new,
      qflist_previewer = require('telescope.previewers').vim_buffer_qflist.new,
    },
    extensions = {
      fzy_native = {
        override_generic_sorter = false,
        override_file_sorter = true,
      },
      file_browser = {
        mappings = {
          ['n'] = {
            ['c'] = fb_actions.create,
            ['r'] = fb_actions.rename,
            ['d'] = fb_actions.remove,
            ['o'] = fb_actions.open,
            ['u'] = fb_actions.goto_parent_dir,
          },
        },
      },
    },
  })
  require('telescope').load_extension('fzy_native')
  require('telescope').load_extension('dotfiles')
  require('telescope').load_extension('gosource')
  require('telescope').load_extension('file_browser')
  require('telescope').load_extension('app')
end

function config.nvim_treesitter()
  vim.opt.foldmethod = 'expr'
  vim.opt.foldexpr = 'nvim_treesitter#foldexpr()'

  local ignored = {
    'phpdoc',
    'astro',
    'arduino',
    'beancount',
    'bibtex',
    'bluprint',
    'eex',
    'ecma',
    'elvish',
    'embedded_template',
    'vala',
    'wgsl',
    'verilog',
    'twig',
    'turtle',
    'm68k',
    'hocon',
    'lalrpop',
    'ledger',
    'meson',
    'mehir',
    'rasi',
    'rego',
    'racket',
    'pug',
    'java',
    'tlaplus',
    'supercollider',
    'slint',
    'sparql',
    'rst',
    'rnoweb',
    'm68k',
  }

  require('nvim-treesitter.configs').setup({
    ignore_install = ignored,
    highlight = {
      enable = true,
    },
    textobjects = {
      select = {
        enable = true,
        keymaps = {
          ['af'] = '@function.outer',
          ['if'] = '@function.inner',
          ['ac'] = '@class.outer',
          ['ic'] = '@class.inner',
        },
      },
    },
  })
end

return config
