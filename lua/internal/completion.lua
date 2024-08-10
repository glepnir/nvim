local api, completion, ffi, lsp = vim.api, vim.lsp.completion, require('ffi'), vim.lsp
local au, pumvisible, vimstate = api.nvim_create_autocmd, vim.fn.pumvisible, vim.fn.state
local ms, uv = vim.lsp.protocol.Methods, vim.uv
local TextChangedI, InsertCharPre = 'TextChangedI', 'InsertCharPre'

ffi.cdef([[
  typedef int32_t linenr_T;
  char *ml_get(linenr_T lnum);
]])

local function has_word_before(triggerCharacters)
  local lnum, col = unpack(api.nvim_win_get_cursor(0))
  if col == 0 then
    return false
  end
  local line_text = ffi.string(ffi.C.ml_get(lnum))
  local char_before_cursor = line_text:sub(col, col)
  return char_before_cursor:match('[%w_]')
    and not vim.list_contains(triggerCharacters, char_before_cursor)
end

local function debounce(func, delay)
  local timer = nil ---[[uv_timer_t]]
  return function(...)
    local args = { ... }
    if timer then
      timer:stop()
      timer:close()
    end
    timer = assert(uv.new_timer())
    timer:start(delay, 0, function()
      if timer and not timer:is_closing() then
        timer:stop()
        timer:close()
        timer = nil
      end
      vim.schedule(function()
        xpcall(function()
          func(unpack(args))
        end, function(err)
          vim.notify('Error in debounced trigger function' .. err, vim.log.levels.ERROR)
        end)
      end)
    end)
  end
end

-- hack can completion on any triggerCharacters
local function auto_trigger(bufnr)
  local debounced_trigger = debounce(completion.trigger, 200)
  au(TextChangedI, {
    buffer = bufnr,
    callback = function(args)
      if pumvisible() == 1 or vimstate('m') == 'm' then
        return
      end
      local clients = lsp.get_clients({ bufnr = args.buf, method = ms.textDocument_completion })
      if #clients == 0 then
        return
      end
      --just invoke trigger once even there has many clients.
      vim.iter(clients):any(function(client)
        local triggerchars =
          vim.tbl_get(client, 'server_capabilities', 'completionProvider', 'triggerCharacters')
        if has_word_before(triggerchars) then
          debounced_trigger()
          return true
        end
        return false
      end)
    end,
  })
end

au('LspAttach', {
  callback = function(args)
    local bufnr = args.buf
    local client_id = args.data.client_id
    completion.enable(true, client_id, bufnr, { autotrigger = true })
    auto_trigger(bufnr)
  end,
})

local function feedkeys(key)
  api.nvim_feedkeys(api.nvim_replace_termcodes(key, true, false, true), 'n', true)
end

local function buf_has_client(bufnr)
  return #lsp.get_clients({ bufnr = bufnr, method = ms.textDocument_completion }) > 0
end

local function is_path_related(line, col)
  if col == 0 then
    return false
  end
  local char_before_cursor = line:sub(col, col)
  return char_before_cursor:match('[/%w_%-%.~]')
end

-- completion for directory and files
au(InsertCharPre, {
  callback = function(args)
    if pumvisible() == 1 or vimstate('m') == 'm' then
      return
    end
    local bufnr = args.buf
    local ok = vim.iter({ 'terminal', 'prompt', 'help' }):any(function(v)
      return v == vim.bo[bufnr].buftype
    end)
    if ok then
      return
    end
    local char = vim.v.char
    local lnum, col = unpack(api.nvim_win_get_cursor(0))
    local line_text = ffi.string(ffi.C.ml_get(lnum))
    if char == '/' and is_path_related(line_text, col) then
      feedkeys('<C-X><C-F>')
    elseif not char:match('%s') and not buf_has_client(bufnr) then
      feedkeys('<C-X><C-N>')
    end
  end,
})

-- Add the TextChangedI to eventignore avoid confirm completion thne insert
-- text trigger TextChangedI again.
local function key_with_disable_textchangedi(key)
  vim.opt.eventignore:append(TextChangedI)
  feedkeys(key)
  vim.defer_fn(function()
    vim.opt.eventignore:remove(TextChangedI)
  end, 0)
end

return {
  key_with_disable_textchangedi = key_with_disable_textchangedi,
}
