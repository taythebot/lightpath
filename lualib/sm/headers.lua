local server_id = ngx.var.server_id
local request_id = ngx.var.request_id
local request_country = ngx.var.geoip2_data_country_code
local cache_status = ngx.var.upstream_cache_status or 'MISS'
local cache_key = ngx.var.cache_key
local strip_cookies = ngx.ctx.strip_cookies

ngx.header['Server'] = 'LightPath-CDN'
ngx.header['X-Server-ID'] = server_id
ngx.header['X-Request-ID'] = request_id
ngx.header['X-Request-Country'] = request_country
ngx.header['X-Cache-Status'] = cache_status
ngx.header['X-Cache-Item'] = cache_key

-- Strip cookies
if ngx.ctx.strip_cookies == '1' then
	ngx.header['Set-Cookie'] = ''
end