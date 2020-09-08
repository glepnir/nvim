local global = require 'global'
local utils = require 'lsp.utils'
local vim,api = vim,vim.api
local M = {}

-- lsp peek preview Taken from
-- https://www.reddit.com/r/neovim/comments/gyb077/nvimlsp_peek_defination_javascript_ttserver
local function preview_location(location, context, before_context)
  -- location may be LocationLink or Location (more useful for the former)
  context = context or 15
  before_context = before_context or 0
  local uri = location.targetUri or location.uri
  if uri == nil then
      return
  end
  local bufnr = vim.uri_to_bufnr(uri)
  if not vim.api.nvim_buf_is_loaded(bufnr) then
      vim.fn.bufload(bufnr)
  end
  local range = location.targetRange or location.range
  local contents =
      vim.api.nvim_buf_get_lines(bufnr, range.start.line - before_context, range["end"].line + 1 + context, false)
  local filetype = vim.api.nvim_buf_get_option(bufnr, "filetype")
  return vim.lsp.util.open_floating_preview(contents, filetype)
end

local function preview_location_callback(_, method, result)
  local context = 15
  if result == nil or vim.tbl_isempty(result) then
      print("No location found: " .. method)
      return nil
  end
  if vim.tbl_islist(result) then
     M.floating_buf, M.floating_win = preview_location(result[1], context)
  else
      M.floating_buf, M.floating_win = preview_location(result, context)
  end
end

function M.lsp_peek_definition()
  if vim.tbl_contains(vim.api.nvim_list_wins(), M.floating_win) then
      vim.api.nvim_set_current_win(M.floating_win)
  else
      local params = vim.lsp.util.make_position_params()
      return vim.lsp.buf_request(0, "textDocument/definition", params, preview_location_callback)
  end
end

local function references_preview_location_callback(_,method,result)
  if result == nil or vim.tbl_isempty(result) then
    print("No Location found:" .. method)
    return nil
  end
  if vim.tbl_islist(result) then
    local uri = result[1].targetUri or result[1].uri
    if uri == nil then
        return
    end
    local bufnr = vim.uri_to_bufnr(uri)
    if not vim.api.nvim_buf_is_loaded(bufnr) then
      vim.fn.bufload(bufnr)
    end

    local files = {}
    for index,_ in ipairs(result) do
      files[index] = vim.uri_to_fname(result[index].uri)
    end
    local lines = {}
    for index,_ in ipairs(result) do
      local range = result[index].targetRange or result[index].range
      lines[index] = api.nvim_buf_get_lines(bufnr,range.start.line-0,range["end"].line+1+5,false)
    end
    local title = 'References:'
    local contents = {title}
    -- TODO:better contents
    for k,_ in ipairs(files) do
      table.insert(contents,files[k])
      if type(lines[k]) == table then
        for a,_ in ipairs(lines[k]) do
          table.insert(contents,lines[a])
        end
      end
    end
    print(global.dump(lines))

    M.floatng_buf,M.floating_win = utils.create_float_window(contents)
  end
end

function M.lsp_peek_references()
  local params = vim.lsp.util.make_position_params()
  return vim.lsp.buf_request(0,"textDocument/references",params,references_preview_location_callback)
end

-- jump to definition in split window
function M.lsp_jump_definition()
  local winr = vim.fn.winnr("$")
  local winsize = vim.api.nvim_exec([[
  echo (winwidth(0) - (max([len(line('$')), &numberwidth-1]) + 1)) < 110
  ]],true)
  if winr >= 4 or winsize == 1 then
    vim.lsp.buf.definition()
  else
    vim.api.nvim_command("vsplit")
    vim.lsp.buf.definition()
  end
end


return M
