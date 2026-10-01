local fname = vim.fn.expand('%:p')

local function is_nvim_src(name)
  return name:find('/neovim/', 1, true) ~= nil or name:find('/src/nvim/', 1, true) ~= nil
end

if is_nvim_src(fname) then
  vim.opt_local.textwidth = 120
  vim.api.nvim_create_user_command('NvimGenerateSource', function()
    require('compile').custom({
      cmd = 'make generated-sources',
      silent = true,
      ondone = function(exit_code)
        if exit_code == 0 then
          vim.iter(vim.api.nvim_list_bufs()):each(function(b)
            local bufname = vim.api.nvim_buf_get_name(b)
            if is_nvim_src(bufname) then
              vim.api.nvim_buf_call(b, function()
                local view = nil
                if vim.bo[b].modified then
                  view = vim.fn.winsaveview()
                  vim.cmd('write!')
                end
                vim.cmd('edit!')
                if view then
                  vim.fn.winrestview(view)
                end
              end)
            end
          end)
        end
      end,
    })
  end, {})
elseif fname:match('vim') then
  vim.opt_local.listchars = { tab = '  ' }
else
  vim.opt_local.expandtab = true
  vim.opt_local.shiftwidth = 4
  vim.opt_local.softtabstop = 4
  vim.opt_local.tabstop = 4
end

vim.cmd([[
inoreabbrev <buffer> inc #include
inoreabbrev <buffer> ici #include <stdio.h><CR><C-O><Cmd>call timer_start(0, { -> execute('normal! S')})<CR>
]])
