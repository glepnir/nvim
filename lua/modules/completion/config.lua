local config = {}

function config.nvim_lsp() require('modules.completion.lspconfig') end

local has_words_before = function()
    local line, col = unpack(vim.api.nvim_win_get_cursor(0))
    return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
end

function config.nvim_cmp()
	local cmp = require("cmp")

	cmp.setup({
		preselect = cmp.PreselectMode.Item,
		window = {
			completion = cmp.config.window.bordered(),
			documentation = cmp.config.window.bordered(),
		},
		formatting = {
      fields = {'kind', 'abbr', 'menu'},
			format = function(entry, vim_item)
				local lspkind_icons = {
					Text = "",
					Method = "",
					Function = "",
					Constructor = " ",
					Field = "",
					Variable = "",
					Class = "",
					Interface = "",
					Module = "硫",
					Property = "",
					Unit = " ",
					Value = "",
					Enum = " ",
					Keyword = "ﱃ",
					Snippet = " ",
					Color = " ",
					File = " ",
					Reference = "Ꮢ",
					Folder = " ",
					EnumMember = " ",
					Constant = " ",
					Struct = " ",
					Event = "",
					Operator = "",
					TypeParameter = " ",
				}
				-- load lspkind icons
				vim_item.kind = lspkind_icons[vim_item.kind]..''

				vim_item.menu = ({
					buffer = " Buf",
					nvim_lsp = " Lsp",
					path = " Pat",
					luasnip = " Sni"
				})[entry.source.name]

				return vim_item
			end,
		},
		-- You can set mappings if you want
		mapping = cmp.mapping.preset.insert({
			["<CR>"] = cmp.mapping.confirm({ select = true }),
			["<C-p>"] = cmp.mapping.select_prev_item(),
			["<C-n>"] = cmp.mapping.select_next_item(),
			["<C-d>"] = cmp.mapping.scroll_docs(-4),
			["<C-f>"] = cmp.mapping.scroll_docs(4),
			["<C-e>"] = cmp.mapping.close(),
		}),
		snippet = {
			expand = function(args)
				require("luasnip").lsp_expand(args.body)
			end,
			},
		sources = {
			{ name = "nvim_lsp" },
			{ name = "luasnip" },
			{ name = "path" },
			{ name = "buffer" },
			},
		}
	)
  vim.cmd('hi CmpFloatBorder guifg=red')
end

function config.lua_snip()
	local ls = require('luasnip')
	ls.config.set_config({
		history = true,
		updateevents = "TextChanged,TextChangedI",
	})
	require("luasnip.loaders.from_vscode").lazy_load()
	require("luasnip.loaders.from_vscode").lazy_load({
		paths = {'./snippets/' }
	})
end

function config.auto_pairs()
  require("nvim-autopairs").setup({})
  local status,cmp = pcall(require,"cmp")
  if not status then
    vim.cmd [[packadd nvim-cmp]]
  end
  cmp = require('cmp')
  local cmp_autopairs = require('nvim-autopairs.completion.cmp')
  cmp.event:on( 'confirm_done', cmp_autopairs.on_confirm_done({  map_char = { tex = '' } }))
  cmp_autopairs.lisp[#cmp_autopairs.lisp+1] = "racket"
end

function config.vim_sonictemplate()
    vim.g.sonictemplate_postfix_key = '<C-,>'
    vim.g.sonictemplate_vim_template_dir =
        os.getenv("HOME") .. '/.config/nvim/template'
end

function config.smart_input()
    require('smartinput').setup {['go'] = {';', ':=', ';'}}
end

function config.emmet()
    vim.g.user_emmet_complete_tag = 0
    vim.g.user_emmet_install_global = 0
    vim.g.user_emmet_install_command = 0
    vim.g.user_emmet_mode = 'i'
end

return config
