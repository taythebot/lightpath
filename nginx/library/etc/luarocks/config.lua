-- I do not know what luarocks guys have in mind
-- If they depend on external commands, it seems
-- completely irrelevant to install packages to
-- replace those commands (as you need these freaking
-- commands anyways to install the first modules!!)
-- On top of that it breaks features. BOUH.
fs_use_modules = false

rocks_trees = {
   home..[[/.luarocks]],
   {root="/etc/nginx/library", bin_dir="/etc/nginx/library/bin", lib_dir="/etc/nginx/library/lib/lua/5.1", lua_dir="/etc/nginx/library/share/lua/5.1"}
}

rocks_servers = {
   [[https://raw.githubusercontent.com/torch/rocks/master]],
   [[https://raw.githubusercontent.com/rocks-moonscript-org/moonrocks-mirror/master]]
}
