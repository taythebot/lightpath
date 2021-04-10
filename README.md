# LightPath CDN Nginx Module
Version: 1.0.0-beta

## Description
CDN, content delivery network, written in Lua using Openresty (Nginx). Website configurations (backend, cache rules, edge rules, etc) are stored in Redis.  

If there is interest I will add proper documentation in the future. This project was made public because I don't personally have the time and money to make this into an actual company. A docker file is provided so you can build this into a docker image.

## Note
There is one software that is not included called Ambassador. Ambassador is a custom SSL certificate manager modeled after Netflix's Lemur. You can easily replace it for Lemur in the `ssl.lua` file.

The module also makes heavy usage of Hashicorp Vault to store secret keys for Ambassador and the JWT token which is used to authenticate to the cache purge api. If you are unable to modify the source code to bypass these requirements, open an issue and I'll try my best to work with you.

## Features
* Edge caching
  * Byte range caching
  * Sorted query string
  * Ignore query string
  * Respect origin cache headers
  * Bypass edge cache
* Edge rules - Block or allow by
  * URL path
  * HTTP Referral (Hotlink protection)
  * IP Address and Range
  * Country
  * ASN
  * Force HTTPS
  * Hot linking protection
  * Set edge cache TTL
  * Enforce CORS headers
  * Strip cookies from origin
* Purge cache (Supports wildcard paths)
* Error logging via Sentry
* Remote access logs (Change in log.lua) 
* Ability to use SSL certificates stored remotely
* SSL termination
* Gzip and Brotli compression

## Todo
* Add Load balancing (Simple modification to balancer.lua)
* Rate limiting 
* Web Application Firewall (For now you can use Naxsi or Mod Security)
* Automatic SSL certificates via Let's Encrypt (Can be added via let's encrypt lua module)

## Use Cases
* Running your own CDN network
* Dynamically serve client websites like Netlify and Vercel 

## Files
* Lua module - `/src/lua/` (Install in your lua lib path)
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
