local server = {}

-- gopls configuration template use daemon
server.go = {
  name = "gopls";
  cmd = {"gopls","--remote=auto"};
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

server.rust = {
  name = "rust-analyzer";
  cmd = { "rust-analyzer" };
  filetypes = {"rust"};
  root_patterns = {"Cargo.toml", "rust-project.json"}
}

server.Dockerfile = {
  name = "Dockerlsp";
  cmd = { "docker-langserver", "--stdio" };
  filetypes = { "Dockerfile", "dockerfile" };
  root_patterns = {"Dockerfile"};
}

local lsp_intall_scripts = [=[
cd $HOME
go get golang.org/x/tools/gopls@latest

# clone project
git clone https://github.com/sumneko/lua-language-server
cd lua-language-server
git submodule update --init --recursive

cd 3rd/luamake
ninja -f ninja/macos.ninja
cd ../..
./3rd/luamake/luamake rebuild

npm install -g dockerfile-language-server-nodejs
]=]

function lsp_install_server()
  os.execute("sh -c"..lsp_intall_scripts)
end

return server
