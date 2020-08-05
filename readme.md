# LightPath CDN Nginx Module
Version: 1.0.0-beta

## Files
* Module - `/src/lualib/sm/`
* Nginx Configuration - `/src/nginx/nginx.conf`

## Software Requirements
* Openresty
* Openresty OpenSSL
* Openresty PCRE 
* [libmaxminddb](https://github.com/maxmind/libmaxminddb)
* Redis

## Nginx Dependencies
* [ngx_http_geoip2_module](https://github.com/leev/ngx_http_geoip2_module)
* [ngx_brotli](https://github.com/google/ngx_brotli)

## Lua Dependencies
* [lua-resty-redis](https://github.com/openresty/lua-resty-redis)
* [lua-resty-mlcache](https://github.com/thibaultcha/lua-resty-mlcache)
* [lua-resty-lrucache](https://github.com/openresty/lua-resty-lrucache)
* [lua-resty-template](https://github.com/bungle/lua-resty-template)
* [raven-lua](https://github.com/cloudflare/raven-lua)
* [lua-resty-jwt](https://github.com/cdbattags/lua-resty-jwt)
* [lua-resty-http](https://github.com/ledgetech/lua-resty-http)
