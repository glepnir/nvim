local filetype = {
  {'Shougo/context_filetype.vim',event = 'BufReadPost *'};
  {'HerringtonDarkholme/yats.vim',ft = {'typescript','typescriptreact'}};
  {'MaxMEllon/vim-jsx-pretty',ft = {'javascriptreact','typescriptreact'}};
  {'ziglang/zig.vim',ft = {'zig','zir'}};
  {'ekalinin/Dockerfile.vim', ft = {'Dockerfile','docker-compose'}};
  {'nvim-treesitter/nvim-treesitter',
   ft = {'html','css','typescript','lua','go','rust','toml'},
   config = function()
    require'nvim-treesitter.configs'.setup {
        highlight = {
          enable = true,
        },
        textobjects = {
          select = {
            enable = true,
            keymaps = {
              ["af"] = "@function.outer",
              ["if"] = "@function.inner",
              ["ac"] = "@class.outer",
              ["ic"] = "@class.inner",
            },
          },
        },
      ensure_installed = 'all'
    }
   end
   };
   {'iamcco/markdown-preview.nvim',
    ft = {'markdown','pandoc.markdown','rmd'},
    run = 'cd app && yarn install',
    cmd = {'MarkdownPreview'},
    config = function ()
        vim.g.mkdp_auto_start = 0
    end
   };
}

return filetype
