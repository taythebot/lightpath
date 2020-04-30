local site_config = {}

site_config.LUAROCKS_PREFIX=[[/etc/nginx/library/]]
site_config.LUA_INCDIR=[[/etc/nginx/library/include]]
site_config.LUA_LIBDIR=[[/etc/nginx/library/lib]]
site_config.LUA_BINDIR=[[/etc/nginx/library/bin]]
site_config.LUA_INTERPRETER = [[luajit]]
site_config.LUAROCKS_SYSCONFDIR=[[/etc/nginx/library/etc/luarocks]]
site_config.LUAROCKS_ROCKS_TREE=[[/etc/nginx/library/]]
site_config.LUAROCKS_ROCKS_SUBDIR=[[lib/luarocks/rocks]]
site_config.LUA_DIR_SET = true
site_config.LUAROCKS_UNAME_S=[[Linux]]
site_config.LUAROCKS_UNAME_M=[[x86_64]]
site_config.LUAROCKS_DOWNLOADER=[[wget]]
site_config.LUAROCKS_MD5CHECKER=[[md5sum]]

return site_config
