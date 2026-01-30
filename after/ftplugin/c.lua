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
          local bufname = vim.api.nvim_buf_get_name(curbuf)
          if bufname:find('nvim') then
            if vim.bo[curbuf].modified then
              vim.cmd('write!')
            end
            vim.cmd('edit!')
          end
        end)
      end
    end)
  end, {})
elseif fname:match('vim') then
  vim.opt_local.listchars = { tab = '\\ ' }
else
  vim.opt_local.expandtab = true
  vim.opt_local.shiftwidth = 4
  vim.opt_local.softtabstop = 4
  vim.opt_local.tabstop = 4
end

vim.cmd('inoreabbrev <buffer> #i #include')
