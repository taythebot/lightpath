-- Load essential libraries
local md5 = require 'md5'
local cjson = require 'cjson'

-- Variables
local string = string
local os = os
local cache_path = '/tmp/cache'
local cache_keyfinder = nil
local cache_keyfinder_path = ngx.var.cache_keyfinder_path or 'nginx_cache_keyfinder'
local urls = ngx.ctx.urls
local key = ngx.ctx.key

-- Escape shell commands
local function safe_shell_command_param(input)
    return "'" .. input:gsub("%'", "'\"'\"'" ) .. "'"
end

-- Loop through urls
for k, url in pairs(urls) do
    -- Create cache key
    local cache_key = key .. url .. 'bytes=*-*'

    -- Parse url
    local uri = string.sub(url, 1, -2)

    if not cache_keyfinder then
        local cache_key_re = cache_key:gsub('([%.%[%]])', '\\%1')
        cache_key_re = cache_key_re:gsub(url:gsub('%p','%%%1'), uri .. '.*')
        
        local safe_grep_param = safe_shell_command_param('^KEY: ' .. cache_key_re)
        
        os.execute('grep -Raslm1  ' .. safe_grep_param .. ' ' .. cache_path .. ' | xargs -r rm -f')
    else
        local uri_start = cache_key:find(url, 1, true) or cache_key:len()
        local prefix = safe_shell_command_param(cache_key:sub(1, uri_start-1) .. uri)
        local suffix = ' ' .. safe_shell_command_param(cache_key:sub(uri_start + url:len()))
        os.execute(cache_keyfinder_path .. ' ' .. cache_path .. ' ' .. prefix .. suffix .. ' -d')
    end
end

ngx.header['Content-Type'] = 'application/json; charset=utf-8'
ngx.say(cjson.encode({ success = true, message = 'Cache successfully cleared' }))
ngx.exit(ngx.HTTP_OK)