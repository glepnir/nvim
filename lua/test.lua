local vim = vim
local M = {}

local function ttt(_,method,result)
    print(method)
end
local function for_each_buffer_client(bufnr, callback)
  validate {
    callback = { callback, 'f' };
  }
  bufnr = resolve_bufnr(bufnr)
  local client_ids = all_buffer_active_clients[bufnr]
  if not client_ids or tbl_isempty(client_ids) then
    return
  end
  for client_id in pairs(client_ids) do
    local client = active_clients[client_id]
    if client then
      callback(client, client_id, bufnr)
    end
  end
end
function lsp.buf_request(bufnr, method, params, callback)
  validate {
    bufnr    = { bufnr, 'n', true };
    method   = { method, 's' };
    callback = { callback, 'f', true };
  }
  local client_request_ids = {}
  for_each_buffer_client(bufnr, function(client, client_id, resolved_bufnr)
    local request_success, request_id = client.request(method, params, callback, resolved_bufnr)

    -- This could only fail if the client shut down in the time since we looked
    -- it up and we did the request, which should be rare.
    if request_success then
      client_request_ids[client_id] = request_id
    end
  end)

  local function _cancel_all_requests()
    for client_id, request_id in pairs(client_request_ids) do
      local client = active_clients[client_id]
      client.cancel_request(request_id)
    end
  end

  return client_request_ids, _cancel_all_requests
end
function M.aaa()
  local params = vim.lsp.util.make_position_params()
  vim.lsp.buf_request(0,"textDocument/references",params,ttt)
  return
end

return M
