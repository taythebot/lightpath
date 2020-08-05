ngx.header['Server'] = 'LightPath'
ngx.header['X-Server-ID'] = os.getenv('SERVER_ID')
ngx.header['X-Server-Colo'] = os.getenv('SERVER_COLO')
ngx.header['X-Request-ID'] = ngx.var.request_id
ngx.header['X-Request-Country'] = ngx.var.geoip2_data_country_code
ngx.header['X-Cache-Status'] = ngx.var.upstream_cache_status or 'MISS'

-- Strip cookies
if ngx.ctx.strip_cookies == '1' then
	ngx.header['Set-Cookie'] = ''
end

-- CORS headers
if ngx.ctx.cors == '1' then
	ngx.header['Access-Control-Allow-Origin'] = '*'
end