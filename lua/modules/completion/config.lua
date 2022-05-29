local config = {}

function config.nvim_lsp() require('modules.completion.lspconfig') end

local has_words_before = function()
    local line, col = unpack(vim.api.nvim_win_get_cursor(0))
    return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
end

local feedkey = function(key, mode)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(key, true, true, true), mode, true)
end

local cmp_window = {
    border = { '🭽', '▔', '🭾', '▕', '🭿', '▁', '🭼', '▏' },
    winhighlight = table.concat({
      'Normal:NormalFloat',
      'FloatBorder:FloatBorder',
      'CursorLine:Visual',
      'Search:None',
    }, ','),
}

function config.nvim_cmp()
	local cmp = require("cmp")
	cmp.setup({
    window = {
      completion = cmp.config.window.bordered(cmp_window),
      documentation = cmp.config.window.bordered(cmp_window),
    },
		formatting = {
			format = function(entry, vim_item)
				local lspkind_icons = {
					Text = "",
					Method = "",
					Function = "",
					Constructor = "",
					Field = "",
					Variable = "",
					Class = "ﴯ",
					Interface = "",
					Module = "",
					Property = "ﰠ",
					Unit = "",
					Value = "",
					Enum = "",
					Keyword = "",
					Snippet = "",
					Color = "",
					File = "",
					Reference = "",
					Folder = "",
					EnumMember = "",
					Constant = "",
					Struct = "",
					Event = "",
					Operator = "",
					TypeParameter = "",
				}
				-- load lspkind icons
				vim_item.kind = string.format("%s %s", lspkind_icons[vim_item.kind], vim_item.kind)

				vim_item.menu = ({
					buffer = "[BUF]",
					nvim_lsp = "[LSP]",
					path = "[PATH]",
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
      ["<Tab>"] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.select_next_item()
        elseif vim.fn["vsnip#available"](1) == 1 then
          feedkey("<Plug>(vsnip-expand-or-jump)", "")
        elseif has_words_before() then
          cmp.complete()
        else
          fallback()
        end
      end, { "i", "s" }),
      ["<S-Tab>"] = cmp.mapping(function()
        if cmp.visible() then
          cmp.select_prev_item()
        elseif vim.fn["vsnip#jumpable"](-1) == 1 then
          feedkey("<Plug>(vsnip-jump-prev)", "")
        end
      end, { "i", "s" }),
    }),
		snippet = {
			expand = function(args)
        vim.fn["vsnip#anonymous"](args.body)
			end,
		},
		sources = {
			{ name = "nvim_lsp" },
      { name = "vsnip" },
      { name = "path" },
      { name = "buffer" },
		},
	})
end

function config.vim_vsnip()
    vim.g.vsnip_snippet_dir = os.getenv('HOME') .. '/.config/nvim/snippets'
end

function config.auto_pairs()
  require("nvim-autopairs").setup({})
  local status,cmp = pcall(require,"cmp")
  if not status then
    vim.cmd [[packadd nvim-cmp]]
  end
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
