# LightPath CDN Nginx Module
Version: 1.0.0-beta

## Description
CDN, content delivery network, written in Lua using Openresty (Nginx). Website configurations (backend, cache rules, edge rules, etc) are stored in Redis.  

If there is interest I will add proper documentation in the future. This project was made public because I don't personally have the time and money to make this into an actual company. A docker file is provided so you can build this into a docker image.

There is one software that is not included called Ambassador. Ambassador is a custom SSL certificate manager modeled after Netflix's Lemur. You can easily replace it for Lemur in the `ssl.lua` file. 

## Features
* Edge caching
* Edge rules
* IP whitelist and blacklist

## Todo
* Add Load balancing (Simple modification to balancer.lua)
* Rate limiting 
* Web Application Firewall (For now you can use Naxsi or Mod Security)

## Files
* Module - `/src/lualib/sm/`
* Nginx Configuration - `/src/nginx/nginx.conf`

## Software
* Redis
* Openresty 1.17.8.2 (Nginx 1.17.8)
* Openresty OpenSSL 1.1.1g
* Openresty PCRE 8.44
* LuaJIT 5.1
* [libmaxminddb](https://github.com/maxmind/libmaxminddb)

## Nginx Modules
* [ngx_http_geoip2_module](https://github.com/leev/ngx_http_geoip2_module)
* [ngx_brotli](https://github.com/google/ngx_brotli)

## Lua Dependencies
* [lua-resty-mlcache](https://github.com/thibaultcha/lua-resty-mlcache)
* [lua-resty-template](https://github.com/bungle/lua-resty-template)
* [raven-lua](https://github.com/cloudflare/raven-lua)
  * lua-cjson
  * luasocket
* [lua-resty-jwt](https://github.com/cdbattags/lua-resty-jwt)
* [lua-resty-http](https://github.com/ledgetech/lua-resty-http)
