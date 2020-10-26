local global = {}
local home    = os.getenv("HOME")
local path_sep = global.is_windows and '\\' or '/'

function global:load_variables()
  self.is_mac     = jit.os == 'OSX'
  self.is_linux   = jit.os == 'Linux'
  self.is_windows = jit.os == 'Windows'
  self.vim_path    = home .. path_sep..'.config'..path_sep..'nvim'
  self.cache_dir   = home .. path_sep..'.cache'..path_sep..'vim'..path_sep
  self.modules_dir = self.vim_path .. path_sep..'modules'
  self.path_sep = path_sep
  self.home = home
end


global:load_variables()

return global
