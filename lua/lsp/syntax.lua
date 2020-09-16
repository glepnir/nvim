local M = {}
local api = vim.api

function M.apply_syntax()
  api.nvim_command([[syntax region ReferencesTitile start=/\s[A-z]\+:/ end=/\s/]])
  api.nvim_command([[syntax region ReferencesIcon start=/\s\S\s\s/ end=/\s/]])
  api.nvim_command([[syntax region ReferencesCount start=/[0-9]\sReferences/ end=/$/]])
  api.nvim_command([[syntax region DefinitionCount start=/[0-9]\sDefinitions/ end=/$/]])
  api.nvim_command([[syntax region TargetFileName start=/\[[0-9]\]\s\([A-z0-9_]\+\/\)\+\([A-z0-9_]\+\)\.[A-z]\+/ end=/$/]])
  api.nvim_command([[syntax region HelpTitle start=/Help:/ end=/$/]])
  api.nvim_command([[syntax region HelpItem start=/\[[A-z]\+\(\s\)\+:\s\([A-z]\+\)\s\?[A-z]\+/ end=/$/]])
  api.nvim_command("hi LspFloatWinBorder guifg=#6699cc")
  api.nvim_command("hi ReferencesTitile guifg=#EC5f67 gui=bold")
  api.nvim_command("hi ReferencesCount guifg=#2e6ce8 gui=bold")
  api.nvim_command("hi DefinitionCount guifg=#2e6ce8 gui=bold")
  api.nvim_command("hi TargetFileName guifg=#a4e34b gui=bold")
  api.nvim_command("hi ReferencesIcon guifg=#e3bc10")
  api.nvim_command("hi HelpTitle guifg=red")
  api.nvim_command("hi default link HelpItem Comment")
end

return M

