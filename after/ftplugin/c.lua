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
                if vim.bo[curbuf].modified then
                  vim.cmd('write!')
                end
                vim.cmd('edit!')
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

vim.cmd('inoreabbrev <buffer> #i #include')
--
-- local augroup = vim.api.nvim_create_augroup('indentlines', {})
--
-- local function guides(sw)
--   if sw == 0 then
--     sw = vim.bo.tabstop
--   end
--   local char = '┆' .. (' '):rep(sw - 1)
--   vim.opt_local.listchars:append({ leadmultispace = char })
-- end
--
-- vim.api.nvim_create_autocmd('OptionSet', {
--   pattern = 'shiftwidth',
--   group = augroup,
--   callback = function()
--     guides(vim.v.option_new)
--   end,
-- })
--
-- vim.api.nvim_create_autocmd('BufWinEnter', {
--   group = augroup,
--   callback = function(args)
--     guides(vim.bo[args.buf].shiftwidth)
--   end,
-- })
