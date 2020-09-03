
server = {}

-- gopls configuration template
server.go = {
  name = "gopls";
  -- A table to store our root_dir to client_id lookup. We want one LSP per
  -- root directory, and this is how we assert that.
  store = {};
  cmd = {"gopls"};
  filetypes = {'go','gomod'};
  root_patterns = {'go.mod','.git'};
  -- https://github.com/golang/tools/blob/master/gopls/doc/settings.md#settings
  init_options = {
    usePlaceholders=true;
    completeUnimported=true;
  };
}


