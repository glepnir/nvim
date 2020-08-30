require 'global'

options = {}

function options:new()
  instance = {}
  setmetatable(instance,self)
  self.__index = self
  return instance
end

function options:define_options()
    self.mouse          = "nv";
    self.report         = 0;
    self.errorbells     = true;
    self.visualbell     = true;
    self.hidden         = true;
    self.fileformats    = {'unix','mac','dos'};
    self.magic          = true;
    self.virtualedit    = "block";
    self.synmaxcol      = 2500;
    self.formatoptions  = "1jcroql";
    self.encoding       = "utf-8";
    self.viewoptions    = "folds,cursor,curdir,slash,unix";
    self.sessionoptions = "curdir,help,tabpages,winsize";
    self.clipboard      = "unnamedplus";
    self.wildignorecase = true;
    self.wildignore     = {'.git','.hg','.svn','*.pyc','*.o','*.out','*.jpg','*.jpeg','*.png','*.gif','*.zip','**/tmp/**','*.DS_Store','**/node_modules/**','**/bower_modules/**'};
    self.backup         = false;
    self.writebackup    = false;
    self.undofile       = true;
    self.swapfile       = false;
    self.directory      = cache_dir .. "swag/";
    self.undodir        = cache_dir .. "undo/";
    self.backupdir      = cache_dir .. "backup/";
    self.viewdir        = cache_dir .. "view/";
    self.spellfile      = cache_dir .. "spell/en.uft-8.add";
    self.history        = 2000;
    self.shada          = "!,'300,<50,@100,s10,h";
    self.backupskip     = {'/tmp/*','$TMPDIR/*','$TMP/*','$TEMP/*','*/shm/*','/private/var/*','.vault.vim'};

    self.textwidth      = 80;
    self.expandtab      = true;
    self.tabstop        = 2;
    self.shiftwidth     = 2;
    self.softtabstop    = -1;
    self.smarttab       = true;
    self.autoindent     = true;
    self.shiftround     = true;
    self.breakindentopt = "shift:2,min:20";

    self.timeout        = true;
    self.ttimeout       = true;
    self.timeoutlen     = 500;
    self.ttimeoutlen    = 10;
    self.updatetime     = 100;
    self.redrawtime     = 1500;

    self.ignorecase     = true;
    self.smartcase      = true;
    self.infercase      = true;
    self.incsearch      = true;
    self.wrapscan       = true;

    self.complete       = ".,w,b,k";
    self.inccommand     = "nosplit";

    self.grepformat     = "%f:%l:%c:%m";
    self.grepprg        = [[rg\ --hidden\ --vimgrep\ --smart-case\ --]];

    self.wrap           = false;
    self.linebreak      = true;
    self.breakat        = [[\ \	;:,!?]];
    self.startofline    = false;
    self.whichwrap      = "h,l,<,>,[,],~";
    self.splitbelow     = true;
    self.splitright     = true;
    self.switchbuf      = "useopen";
    self.backspace      = "indent,eol,start";
    self.diffopt        = {'filler','iwhite','internal','algorithm:patience'};
    self.completeopt    = {'menu','menuone','noselect','noinsert'};
    self.jumpoptions    = "stack";

    self.showmode       = false;
    self.shortmess      = "aoOTIcF";
    self.scrolloff      = 2;
    self.sidescrolloff  = 5;
    self.ruler          = false;
    self.list           = true;

    self.showtabline    = 2;
    self.winwidth       = 30;
    self.winminwidth    = 10;
    self.pumheight      = 15;
    self.helpheight     = 12;
    self.previewheight  = 12;

    self.number         = true;
    self.showcmd        = false;
    self.cmdheight      = 2;
    self.cmdwinheight   = 5;
    self.equalalways    = false;
    self.laststatus     = 2;
    self.colorcolumn    = "100";
    self.display        = "lastline";

    self.foldenable     = true;
    self.foldmethod     = "indent";
    self.foldlevelstart = 99;

    self.signcolumn     = "yes";
    self.showbreak      = "↳  ";
    self.listchars      = {"tab:»·","nbsp:+","trail:·","extends:→","precedes:←"};
    self.conceallevel   = 2;
    self.concealcursor  = "niv";
    self.termguicolors  = true;
    self.pumblend       = 10;
    self.winblend       = 10;
  if is_mac then
    vim.g.clipboard = {
      name = "macOS-clipboard",
      copy = {
        ["+"] = "pbcopy",
        ["*"] = "pbcopy",
      },
      paste = {
        ["+"] = "pbpaste",
        ["*"] = "pbpaste",
      },
      cache_enabled = 0
    }
    vim.g.python_host_prog = '/usr/bin/python'
    vim.g.python3_host_prog = '/usr/local/bin/python3'
  end
end

function options:load_options()
  self:define_options()
  for k, v in pairs(self) do
    if type(v) == 'table' then
      local values = ''
      for k2, v2 in pairs(v) do
        if k2 == 1 then
          values = values .. v2
        else
          values = values .. ',' .. v2
        end
      end
      vim.api.nvim_command('set ' .. k .. '=' .. values)
    else
      vim.api.nvim_set_option(k,v)
    end
  end
end

