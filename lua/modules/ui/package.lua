local package = require("core.pack").package
local conf = require("modules.ui.config")

package({
	"glepnir/flipped.nvim",
	dev = true,
	config = function()
		vim.cmd.colorscheme("flipped")
	end,
})

package({
	"glepnir/dashboard-nvim",
	dev = true,
	event = "VimEnter",
	config = conf.dashboard,
	dependencies = { "nvim-tree/nvim-web-devicons" },
})

package({
	"glepnir/whiskyline.nvim",
	dev = true,
	config = conf.whisky,
	dependencies = { "nvim-tree/nvim-web-devicons" },
})

local enable_indent_filetype = {
	"go",
	"lua",
	"sh",
	"rust",
	"cpp",
	"typescript",
	"typescriptreact",
	"javascript",
	"json",
	"python",
}

package({
	"lukas-reineke/indent-blankline.nvim",
	ft = enable_indent_filetype,
	config = conf.indent_blankline,
})

package({
	"lewis6991/gitsigns.nvim",
	event = { "BufRead", "BufNewFile" },
	config = conf.gitsigns,
})
