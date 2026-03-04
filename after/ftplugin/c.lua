local fname = vim.fn.expand('%:p')

if fname:match('neovim') or fname:match('nvim') then
  vim.opt_local.textwidth = 120
  vim.api.nvim_create_user_command('NvimGenerateSource', function()
    vim.system({ 'make', 'generated-sources' }, {
      text = true,
    }, function(out)
      if out.code ~= 0 or #out.stderr > 0 then
        vim.schedule(function()
          vim.api.nvim_echo(
            { { ('Exit code: %d %s'):format(out.code, out.stderr) } },
            true,
            { err = true }
          )
        end)
      else
        vim.schedule(function()
          local curbuf = vim.api.nvim_get_current_buf()
          vim.iter(vim.api.nvim_list_bufs()):map(function(b)
            local bufname = vim.api.nvim_buf_get_name(b)
            if bufname:find('nvim') then
              vim.api.nvim_buf_call(b, function()
                local view = nil
                if vim.bo[curbuf].modified then
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
        end)
      end
    end)
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
inoreabbrev <buffer> mal malloc(sizeof());<Left><Left><Left><C-O>:call timer_start(0, { -> execute('normal! X')})<CR>
]])
