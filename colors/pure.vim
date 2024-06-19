" Name:       pure.vim
" Version:    0.1
" Maintainer: glepnir <https://github.com/glepnir>
" License:    The MIT License (MIT)
"
" A minimal colour scheme for Vim and Neovim
" modified from neovim default colorscheme

set background=dark
hi clear

if exists("syntax_on")
  syntax reset
endif

let g:colors_name = 'pure'

let s:LightBlue = '#a6dbff'

hi Normal guifg=#e0e2ea guibg=#14161b
hi CursorLine guibg=#2c2e33
hi ColorColumn guibg=#4f5258 cterm=reverse
hi QuickFixLine guifg=#8cf8f7 ctermfg=14
hi link Whitespace NonText
hi link MsgSeparator StatusLine
hi NormalFloat guibg=#07080d
hi link FloatBorder NormalFloat
hi WinBar guifg=#9b9ea4 guibg=#07080d cterm=bold gui=bold
hi WinBarNC guifg=#9b9ea4 guibg=#07080d cterm=bold
hi Cursor guifg=#14161b guibg=#e0e2ea
hi link FloatTitle Title
hi link FloatFooter FloatTitle
hi link StatusLineTerm StatusLine
hi link StatusLineTermNC StatusLineNC
hi Underlined cterm=underline gui=underline
hi lCursor guifg=#14161b guibg=#e0e2ea
hi link CursorIM Cursor
hi link Substitute Search
hi link VisualNOS Visual
hi link Character Constant
hi link Boolean Constant
hi link Float Number
hi link Conditional Statement
hi link IncSearch CurSearch
hi link Repeat Statement
hi link Label Statement
hi link Keyword Statement
hi link Exception Statement
hi PreProc guifg=#e0e2ea
hi link Define PreProc
hi link Macro PreProc
hi link PreCondit PreProc
hi link StorageClass Type
hi Type guifg=#fce094 ctermfg=11
hi link Structure Type
hi link Typedef Type
hi link Tag Special
hi Special guifg=#8cf8f7 ctermfg=14
hi link SpecialChar Special
hi link SpecialComment Special
hi link Debug Special
hi link Ignore Normal
hi link LspCodeLens NonText
hi SpecialKey guifg=#4f5258
hi EndOfBuffer guifg=#14161b
hi NonText guifg=#4f5258
hi TermCursor cterm=reverse
hi Directory guifg=#8cf8f7 ctermfg=14
hi ErrorMsg guifg=#ffc0b9 ctermfg=9
hi CurSearch guifg=#07080d guibg=#fce094 ctermfg=0 ctermbg=11
hi Search guifg=#eef1f8 guibg=#6b5300 ctermfg=0 ctermbg=11
hi MoreMsg guifg=#8cf8f7 ctermfg=14
hi ModeMsg guifg=#b3f6c0 ctermfg=10
hi LineNr guifg=#4f5258
hi link LineNrAbove LineNr
hi link LineNrBelow LineNr
hi CursorLineNr cterm=bold gui=bold
hi link CursorLineSign SignColumn
hi SignColumn guifg=#4f5258
hi link CursorLineFold FoldColumn
hi link FoldColumn SignColumn
hi Question guifg=#8cf8f7 ctermfg=14
hi StatusLine guifg=#2c2e33 guibg=#c4c6cd cterm=reverse
hi StatusLineNC guifg=#c4c6cd guibg=#2c2e33 cterm=bold,underline
hi link WinSeparator Normal
hi link VertSplit WinSeparator
hi Visual guibg=#4f5258 ctermfg=0 ctermbg=15
hi link WildMenu PmenuSel
hi PmenuSel guifg=#2c2e33 guibg=#e0e2ea cterm=reverse,underline
hi Folded guifg=#9b9ea4 guibg=#2c2e33
hi DiffAdd guifg=#eef1f8 guibg=#005523 ctermfg=0 ctermbg=10
hi DiffChange guifg=#eef1f8 guibg=#4f5258
hi DiffDelete guifg=#ffc0b9 ctermfg=9 cterm=bold gui=bold
hi DiffText guifg=#eef1f8 guibg=#007373 ctermfg=0 ctermbg=14
hi Conceal guifg=#4f5258
hi SpellBad guisp=#ffc0b9 cterm=undercurl gui=undercurl
hi SpellCap guisp=#fce094 cterm=undercurl gui=undercurl
hi SpellRare guisp=#8cf8f7 cterm=undercurl gui=undercurl
hi SpellLocal guisp=#b3f6c0 cterm=undercurl gui=undercurl
hi Pmenu guibg=#2c2e33 cterm=reverse
hi link @string.special SpecialChar
hi PmenuMatch guifg=#007373 guibg=#2c2e33 blend=0
hi PmenuMatchSel guifg=#007373 guibg=#e0e2ea blend =0
hi link PmenuKind Pmenu
hi link PmenuKindSel PmenuSel
hi link PmenuExtra Pmenu
hi link PmenuExtraSel PmenuSel
hi link PmenuSbar Pmenu
hi PmenuThumb guibg=#4f5258
hi link TabLine StatusLineNC
hi TabLineSel cterm=bold gui=bold
hi link TabLineFill TabLine
hi CursorColumn guibg=#2c2e33
hi Identifier guifg=#a6dbff ctermfg=12
hi link @function Function
hi link @function.builtin Special
hi link @constructor Special
hi link @operator Operator
hi Operator guifg=#e0e2ea
hi link @keyword Keyword
hi link @punctuation Delimiter
hi Delimiter guifg=#e0e2ea
hi link @punctuation.special Special
hi link @comment Comment
hi link @comment.error DiagnosticError
hi link @comment.warning DiagnosticWarn
hi link @comment.note DiagnosticInfo
hi link @comment.todo Todo
hi Todo guifg=#e0e2ea cterm=bold gui=bold
hi link @markup Special
hi @markup.strong cterm=bold gui=bold
hi @markup.italic cterm=italic gui=italic
hi @markup.strikethrough cterm=strikethrough gui=strikethrough
hi @markup.underline cterm=underline gui=underline
hi link @markup.heading Title
hi link @markup.link Underlined
hi link @diff.plus Added
hi Added guifg=#b3f6c0 ctermfg=10
hi WarningMsg guifg=#fce094 ctermfg=11
hi link @diff.minus Removed
hi Removed guifg=#ffc0b9 ctermfg=9
hi link @diff.delta Changed
hi Changed guifg=#8cf8f7 ctermfg=14
hi link @tag Tag
hi link @tag.builtin Special
hi link @lsp.type.class @type
hi link @lsp.type.comment @comment
hi link @lsp.type.decorator @attribute
hi link @lsp.type.enum @type
hi link @lsp.type.enumMember @constant
hi link @lsp.type.event @type
hi link @lsp.type.function @function
hi link @lsp.type.interface @type
hi link @lsp.type.keyword @keyword
hi link @lsp.type.macro @constant.macro
hi link Number Constant
hi link @lsp.type.modifier @type.qualifier
hi link @lsp.type.namespace @module
hi link @lsp.type.number @number
hi Title guifg=#e0e2ea cterm=bold gui=bold
hi link @lsp.type.parameter @variable.parameter
hi link @lsp.type.property @property
hi link @lsp.type.regexp @string.regexp
hi link @lsp.type.string @string
hi link @lsp.type.struct @type
hi link @lsp.type.type @type
hi link @lsp.type.typeParameter @type.definition
hi link @lsp.type.variable @variable
hi link @lsp.mod.deprecated DiagnosticDeprecated
hi DiagnosticDeprecated guisp=#ffc0b9 cterm=strikethrough gui=strikethrough
hi FloatShadow guibg=#4f5258 ctermbg=0
hi FloatShadowThrough guibg=#4f5258 ctermbg=0
hi MatchParen guibg=#4f5258 cterm=bold,underline gui=bold
hi Error guifg=#eef1f8 guibg=#590008 ctermfg=0 ctermbg=9
hi Constant guifg=#e0e2ea
hi String guifg=#b3f6c0 ctermfg=10
hi Function guifg=#a6dbff ctermfg=12
hi Statement guifg=#e0e2ea cterm=bold gui=bold
hi link @lsp.type.operator @operator
hi link @lsp.type.method @function.method
hi link @property @variable
hi link @attribute.builtin Special
hi link @attribute Macro
hi link @type.builtin Type
hi link @type Type
hi link @number.float Float
hi link @number Number
hi link @boolean Boolean
hi link @character.special SpecialChar
hi link @character Character
hi link @string.special.url Underlined
hi link @string.escape @string.special
hi link @string.regexp @string.special
hi link @string String
hi link @label Label
hi link @module.builtin Special
hi link @module Structure
hi link @constant.builtin Special
hi link @constant Constant
hi link @variable.parameter.builtin Special
hi link @variable.builtin Special
hi Comment guifg=#9b9ea4
hi link DiagnosticUnnecessary Comment
hi link DiagnosticSignOk DiagnosticOk
hi link DiagnosticSignHint DiagnosticHint
hi link DiagnosticSignInfo DiagnosticInfo
hi link DiagnosticSignWarn DiagnosticWarn
hi link DiagnosticSignError DiagnosticError
hi link DiagnosticVirtualTextOk DiagnosticOk
hi link DiagnosticVirtualTextHint DiagnosticHint
hi link DiagnosticVirtualTextInfo DiagnosticInfo
hi link DiagnosticVirtualTextWarn DiagnosticWarn
hi link DiagnosticVirtualTextError DiagnosticError
hi DiagnosticOk guifg=#b3f6c0 ctermfg=10
hi link DiagnosticFloatingOk DiagnosticOk
hi DiagnosticHint guifg=#a6dbff ctermfg=12
hi link DiagnosticFloatingHint DiagnosticHint
hi DiagnosticInfo guifg=#8cf8f7 ctermfg=14
hi link DiagnosticFloatingInfo DiagnosticInfo
hi DiagnosticWarn guifg=#fce094 ctermfg=11
hi link DiagnosticFloatingWarn DiagnosticWarn
hi DiagnosticError guifg=#ffc0b9 ctermfg=9
hi link DiagnosticFloatingError DiagnosticError
hi DiagnosticUnderlineError guisp=#ffc0b9 cterm=underline gui=underline
hi DiagnosticUnderlineWarn guisp=#fce094 cterm=underline gui=underline
hi DiagnosticUnderlineInfo guisp=#8cf8f7 cterm=underline gui=underline
hi DiagnosticUnderlineHint guisp=#a6dbff cterm=underline gui=underline
hi DiagnosticUnderlineOk guisp=#b3f6c0 cterm=underline gui=underline
hi link SnippetTabstop Visual
hi link LspSignatureActiveParameter Visual
hi link LspReferenceWrite LspReferenceText
hi link LspReferenceText Visual
hi link LspReferenceRead LspReferenceText
hi link LspInlayHint NonText
hi link LspCodeLensSeparator LspCodeLens

hi IndentLine guifg=#2c2e33
hi IndentLineCurrent guifg=#9b9ea4

hi DashboardHeader guifg=#b3f6c0
hi GitSignsAdd guifg=#005523
hi GitSignsChange guifg=#007373
hi GitSignsDelete guifg=#590008
