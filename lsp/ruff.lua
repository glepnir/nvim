--- Refer to the [documentation](https://docs.astral.sh/ruff/editors/) for more details.
return {
  cmd = { 'ruff', 'server' },
  filetypes = { 'python' },
  root_markers = { 'pyproject.toml', 'ruff.toml', '.ruff.toml', '.git' },
}
