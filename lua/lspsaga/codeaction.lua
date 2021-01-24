local api,lsp = vim.api,vim.lsp
local window = require('lspsaga.window')
local saga = require('lspsaga')
local wrap = require('lspsaga.wrap')

local code_actions = {}
local contents_bufnr,contents_winid,border_winid

local function code_action(context)
  vim.validate { context = { context, 't', true } }
  context = context or { diagnostics = vim.lsp.diagnostic.get_line_diagnostics() }
  local params = vim.lsp.util.make_range_params()
  params.context = context
  local response = vim.lsp.buf_request_sync(0,'textDocument/codeAction', params,1000)

  local contents = {}
  local title = saga.config_values['code_action_icon'] .. 'CodeActions:'
  table.insert(contents,title)

  for index,action in pairs(response[1].result) do
    local action_title = '['..index..']' ..' '.. action.title
    table.insert(contents,action_title)
    table.insert(code_actions,action)
  end

  -- insert blank line
  local truncate_line = wrap.add_truncate_line(contents)
  table.insert(contents,2,truncate_line)

  contents_bufnr,contents_winid,_,border_winid = window.create_float_window(contents,'LspSagaCodeAction',1,true)

  api.nvim_buf_add_highlight(contents_bufnr,-1,"LspSagaCodeActionTitle",0,0,-1)
  api.nvim_buf_add_highlight(contents_bufnr,-1,"LspSagaCodeActionTruncateLine",1,0,-1)
  api.nvim_command('nnoremap <buffer><nowait><silent><cr> <cmd>lua require("lspsaga.codeaction").do_code_action()<CR>')
end

local do_code_action = function()
  local number = tonumber(vim.fn.expand("<cword>"))
  local action = code_actions[number]

  if action.edit or type(action.command) == "table" then
    if action.edit then
      vim.lsp.util.apply_workspace_edit(action.edit)
    end
    if type(action.command) == "table" then
      vim.lsp.buf.execute_command(action.command)
    end
  else
    vim.lsp.buf.execute_command(action)
  end
  api.nvim_win_close(contents_winid,true)
  api.nvim_win_close(border_winid,true)
  code_actions = {}
end

return {
  code_action = code_action,
  do_code_action = do_code_action
}
