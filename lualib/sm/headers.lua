ngx.header['Server'] = 'LightPath-CDN'
ngx.header['X-Server-ID'] = ngx.var.server_id
ngx.header['X-Server-Colo'] = ngx.var.server_colo
ngx.header['X-Request-ID'] = ngx.var.request_id
ngx.header['X-Request-Country'] = ngx.var.geoip2_data_country_code
ngx.header['X-Cache-Status'] = ngx.var.upstream_cache_status or 'MISS'

-- Strip cookies
if ngx.ctx.strip_cookies == '1' then
	ngx.header['Set-Cookie'] = ''
end