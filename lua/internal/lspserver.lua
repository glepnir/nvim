local global = require 'domain.global'
local server = require 'lspsaga.server'
local vim = vim

-- gopls configuration template use daemon
server.go = {
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
  cmd = { global.home.."/workstation/lua-language-server/bin/macOS/lua-language-server", "-E",
          global.home.."/workstation/lua-language-server/main.lua"};
  filetypes = {'lua'};
  root_patterns = {'.git'};
  settings = {
    Lua = {
      diagnostics = {
        enable = true,
        globals = {"vim"}
      },
      runtime = {version = "LuaJIT"},
      workspace = {
        library = vim.list_extend({[vim.fn.expand("$VIMRUNTIME/lua")] = true},{}),
      },
    },
  }
}

server.rust = {
  cmd = { "rust-analyzer" };
  filetypes = {"rust"};
  root_patterns = {"Cargo.toml", "rust-project.json"}
}

server.zig = {
  cmd = { "zls" };
  filetypes = {"zig"};
  root_patterns = {".git"}
}

server.sh = {
  cmd = { "bash-language-server", "start" };
  filetypes = { "sh" };
  root_patterns = {".git"}
}

server.Dockerfile = {
  cmd = { "docker-langserver", "--stdio" };
  filetypes = { "Dockerfile", "dockerfile" };
  root_patterns = {"Dockerfile"};
}

server.tsserver = {
  cmd = {"typescript-language-server","--stdio"};
  filetypes = {"javascript", "javascriptreact", "typescript", "typescriptreact"};
  root_patterns  = {"package.json", "tsconfig.json", ".git"}
}

server.cssls = {
  cmd = {'css-languageserver','--stdio'};
  filetypes = {"css", "scss", "less"};
}

server.diagnosticls = {
  filetypes = {"javascript", "javascriptreact", "typescript", "typescriptreact"};
  root_patterns  = {"package.json", "tsconfig.json", ".git"},
  init_options = {
    linters = {
        eslint = {
            command = "./node_modules/.bin/eslint",
            rootPatterns = {".git"},
            debounce = 100,
            args = {
                "--stdin",
                "--stdin-filename",
                "%filepath",
                "--format",
                "json"
            },
            sourceName = "eslint",
            parseJson = {
                errorsRoot = "[0].messages",
                line = "line",
                column = "column",
                endLine = "endLine",
                endColumn = "endColumn",
                message = "${message} [${ruleId}]",
                security = "severity"
            },
            securities = {
                [2] = "error",
                [1] = "warning"
            }
        },
    filetypes = {
        javascript = "eslint",
        typescript = "eslint"
      }
    }
  }
}

local lsp_intall_scripts = [=[
# Install gopls
cd $HOME
go get golang.org/x/tools/gopls@latest

# clone lua lsp and build it
git clone https://github.com/sumneko/lua-language-server
cd lua-language-server
git submodule update --init --recursive

cd 3rd/luamake
ninja -f ninja/macos.ninja
cd ../..
./3rd/luamake/luamake rebuild

# Install dockerfile lsp server
npm install -g dockerfile-language-server-nodejs

# Install bash lsp server
npm i -g bash-language-server

# Install rust-analyzer
RUSTANALYZER=/tmp/rust-analyzer
curl -L https://github.com/rust-analyzer/rust-analyzer/releases/latest/download/rust-analyzer-mac -o $RUSTANALYZER
chmod +x $RUSTANALYZER
mv $RUSTANALYZER /usr/local/bin/

]=]
