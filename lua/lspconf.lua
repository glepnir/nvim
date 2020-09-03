
server = {}

-- gopls configuration template
server.go = {
  name = "gopls";
  cmd = {"gopls"};
  filetypes = {'go','gomod'};
  root_patterns = {'go.mod','.git'};
  -- https://github.com/golang/tools/blob/master/gopls/doc/settings.md#settings
  init_options = {
    usePlaceholders=true;
    completeUnimported=true;
  };
}

server.lua = {
  name = "lualsp";
  cmd = {"/Users/stephen/lua-language-server/bin/macOS/lua-language-server", "-E", "/Users/stephen/lua-language-server/main.lua"};
  filetypes = {'lua'};
  root_patterns = {'.git'};
}

