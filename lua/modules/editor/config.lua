local M = {}
local api = vim.api

function M.nvim_treesitter()
  vim.opt.foldmethod = "expr"
  vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
  require("nvim-treesitter.configs").setup({
    ensure_installed = {
      "c",
      "cpp",
      "rust",
      "zig",
      "lua",
      "go",
      "python",
      "proto",
      "typescript",
      "javascript",
      "tsx",
      "css",
      "scss",
      "diff",
      "dockerfile",
      "gomod",
      "gosum",
      "gowork",
      "graphql",
      "html",
      "sql",
      "markdown",
      "markdown_inline",
      "json",
      "jsonc",
      "vimdoc",
      "vim",
      "cmake",
    },
    highlight = {
      enable = true,
      disable = function(_, buf)
        local bufname = vim.api.nvim_buf_get_name(buf)
        local max_filesize = 300 * 1024
        local ok, stats = pcall(vim.uv.fs_stat, bufname)
        if ok and stats and stats.size > max_filesize then
          return true
        end
      end,
      additional_vim_regex_highlighting = false,
    },
  })

  api.nvim_create_autocmd("FileType", {
    pattern = { "javascriptreact", "typescriptreact" },
    callback = function(opt)
      if vim.bo[opt.buf].filetype == "lua" and api.nvim_buf_get_name(opt.buf):find("%_spec") then
        vim.treesitter.stop(opt.buf)
      end
      vim.bo[opt.buf].indentexpr = "nvim_treesitter#indent()"
    end,
  })
end

return M
