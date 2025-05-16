return {
  cmd = { 'zls' },
  filetypes = { 'zig', 'zir' },
  root_markers = {
    'build.zig',
    'zls.json',
  },
} --[[@as vim.lsp.Config]]
