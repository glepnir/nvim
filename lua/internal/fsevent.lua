local api = vim.api
local uv = vim.loop
local window = require('lspsaga.window')
local fs = {}
 -- Some path manipulation utilities
local function is_dir(filename)
  local stat = uv.fs_stat(filename)
  return stat and stat.type == 'directory' or false
end

local path_sep = vim.loop.os_uname().sysname == "Windows" and "\\" or "/"
-- Asumes filepath is a file.
local function dirname(filepath)
  local is_changed = false
  local result = filepath:gsub(path_sep.."([^"..path_sep.."]+)$", function()
    is_changed = true
    return ""
  end)
  return result, is_changed
end

local function path_join(...)
  return table.concat(vim.tbl_flatten {...}, path_sep)
end

-- Ascend the buffer's path until we find the rootdir.
-- is_root_path is a function which returns bool
local function buffer_find_root_dir(bufnr, is_root_path)
  local bufname = vim.api.nvim_buf_get_name(bufnr)
  if vim.fn.filereadable(bufname) == 0 then
    return nil
  end
  local dir = bufname
  -- Just in case our algo is buggy, don't infinite loop.
  for _ = 1, 100 do
    local did_change
    dir, did_change = dirname(dir)
    if is_root_path(dir, bufname) then
      return dir, bufname
    end
    -- If we can't ascend further, then stop looking.
    if not did_change then
      return nil
    end
  end
end

function fs:register_root_pattern()
  self.root_pattern = {
    go = {'go.mod','.git'},
    typescript = {'package.json','tsconfig.json','node_modules'},
    javascript = {'package.json','jsconfig.json','node_modules'},
    typescriptreact = {'package.json','jsconfig.json','node_modules'},
    javascriptreact = {'package.json','jsconfig.json','node_modules'},
    lua = {'.git'},
    rust = {'.Cargo.toml'}
  }
end

function fs:get_root_dir()
  self:register_root_pattern()
  local bufnr = api.nvim_get_current_buf()
  local filetype = vim.bo.filetype
  local root_dir = buffer_find_root_dir(bufnr, function(dir)
    for _,pattern in pairs(self.root_pattern[filetype]) do
      if is_dir(path_join(dir,pattern)) then
        return true
      elseif vim.fn.filereadable(path_join(dir, pattern)) == 1 then
        return true
      elseif is_dir(path_join(dir, '.git')) then
        return true
      end
      return false
    end
  end)
  -- We couldn't find a root directory, so ignore this file.
  if not root_dir then
    print('Not found root dir')
    return
  end
  return root_dir
end

function fs:project_files_list()
  self.file_list = {}
  local p = io.popen('rg --files '..self.root_dir)
  for file in p:lines() do
    table.insert(self.file_list,file:sub(self.root_dir:len()+2))
  end
end

function fs:render_window()
  self.root_dir = self:get_root_dir()
  self:project_files_list()
  self.contents = {}
  local project_icon = '   '
  table.insert(self.contents,project_icon..self.root_dir..' ')
  -- get dimensions
  local width = api.nvim_get_option("columns")
  local height = api.nvim_get_option("lines")

  -- calculate our floating window size
  local win_height = math.ceil(height * 0.8 - 4)
  local win_width = math.ceil(width * 0.8)

  -- and its starting position
  local row = math.ceil((height - win_height) / 2 - 1)
  local col = math.ceil((width - win_width)/0.8)

  local opts = {
    relative = "editor",
    height = 1,
    row = row,
    col = col
  }

  local border_opts = {
    border = 1,
    title = 'ProJect'
  }

  local header_opts = {
    contents = self.contents,
    filetype = 'ProJectHeader'
  }

  self.hcb,self.hcw,_,self.hbw = window.create_float_window(header_opts,border_opts,opts)
  api.nvim_buf_add_highlight(self.hcb, 0, 'ProJectIcon', 0, 0, #project_icon)
  api.nvim_buf_add_highlight(self.hcb, 0, 'ProJectPath', 0, #project_icon, -1)
  api.nvim_command('hi ProJectIcon guifg=#98be65 gui=bold')
  api.nvim_command('hi ProJectPath guifg=#a9a1e1 gui=bold')

  local input_border_opts = {
    border = 1,
  }

  local input_opts = {
    relative = "editor",
    width = #self.contents[1] - 2,
    height = 1,
    row = row+3,
    col = col
  }

  local input_content_opts = {
    contents = {},
    filetype = 'ProjectEvent',
    enter = true,
  }

  self.input_cb,self.input_cw,_,self.input_bw = window.create_float_window(input_content_opts,input_border_opts,input_opts)
  local file_input_prefix = api.nvim_create_namespace('file_input_prefix')
  api.nvim_buf_set_option(self.input_cb,'modifiable',true)
  self.prompt_prefix = '> '
  api.nvim_buf_set_option(self.input_cb,'buftype','prompt')
  vim.fn.prompt_setprompt(self.input_cb, self.prompt_prefix)
  api.nvim_buf_add_highlight(self.input_cb, file_input_prefix, 'FileInputPrefix', 0, 0, #self.prompt_prefix)
  vim.cmd [[startinsert!]]
  api.nvim_command('inoremap <buffer><nowait><silent> <cr> <cmd>lua require("internal.fsevent").do_file_action()<CR>')
  api.nvim_command('inoremap <buffer><nowait><silent> <C-c> <cmd>lua require("internal.fsevent").quit_fs_window()<CR>')
  api.nvim_command('hi FileInputPrefix guifg=#d16d9e')
end

function fs:quit_fs_window()
  if vim.fn.mode() == 'i' then
    vim.cmd [[stopinsert]]
  end
  window.nvim_close_valid_window({self.input_cw,self.input_bw,self.hcw,self.hbw})
end

function fs:do_file_action()
  local fname = vim.trim(vim.fn.getline('.'):sub(#self.prompt_prefix+1,-1))
  local complete_name = self.root_dir .. '/'..fname
  os.execute('touch '..complete_name)
  window.nvim_close_valid_window({self.input_cw,self.input_bw,self.hcw,self.hbw})
  vim.cmd('edit '..complete_name)
end

local fsevent = {}

function fsevent.file_event()
  fs:render_window()
end

function fsevent.do_file_action()
  fs:do_file_action()
end

function fsevent.quit_fs_window()
  fs:quit_fs_window()
end

return fsevent
