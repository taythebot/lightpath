ngx.header['Server'] = 'LightPath-CDN'
ngx.header['X-Server-ID'] = ngx.var.server_id
ngx.header['X-Server-Colo'] = ngx.var.server_colo
ngx.header['X-Request-ID'] = ngx.var.request_id
