ngx.header["Server"] = "LightPath-CDN"
ngx.header["X-Server-ID"] = os.getenv("SERVER_ID")
ngx.header["X-Server-Colo"] = os.getenv("SERVER_COLo")
ngx.header["X-Request-ID"] = ngx.var.request_id
