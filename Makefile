nvim ?= nvim
XDG_CACHE_HOME ?= $(HOME)/.cache

default: install

install:
	@mkdir -vp "$(XDG_CACHE_HOME)/vim/"{backup,session,swap,tags,undo}; \
	$(nvim)  -V1 -c -i NONE -N --noplugin -u init.lua -c PackerInstall

create-dirs:
	@mkdir -vp "$(XDG_CACHE_HOME)/vim/"{backup,session,swap,tags,undo}

upgrade:
	$(nvim) -V1 -c -i NONE -N --noplugin -u init.lua -c PackerUpdate

