return {
  cmd = { 'rust-analyzer' },
  filetypes = { 'rust' },
  root_markers = {
    'Cargo.toml',
    'Cargo.lock',
    'rust-project.json',
  },
  before_init = function(init_params, _)
    if vim.system({ 'cargo', 'clippy', '--version' }):wait().code == 0 then
      init_params.initializationOptions = vim.tbl_extend(
        'force',
        init_params.initializationOptions --[[@as table?]]
          or {},
        { check = { command = 'clippy' } }
      )
    end
  end,
} --[[@as vim.lsp.Config]]
