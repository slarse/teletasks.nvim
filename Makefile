BUSTED_VERSION ?= "2.2.0-1"

setup:
	luarocks init
	luarocks config --scope project lua_version 5.1
	luarocks install ./teletasks.nvim-scm-1.rockspec --deps-only 
	luarocks install busted "$(BUSTED_VERSION)"

test:
	nvim -u NONE \
		-c "lua package.path='$(CURDIR)/lua_modules/share/lua/5.1/?.lua;$(CURDIR)/lua_modules/share/lua/5.1/?/init.lua;'..package.path;package.cpath='$(CURDIR)/lua_modules/lib/lua/5.1/?.so;'..package.cpath;local k,l,_=pcall(require,'luarocks.loader') _=k and l.add_context('busted','$(BUSTED_VERSION)')" \
		-l "$(CURDIR)/lua_modules/lib/luarocks/rocks-5.1/busted/$(BUSTED_VERSION)/bin/busted" tests/
.PHONY: run-tests
