# LightPath CDN
Version: 1.0.0-beta

CDN written in Lua using Nginx and Redis.

## Description
CDN, content delivery network, written in Lua using Openresty (Nginx). Website configurations (backend, cache rules, edge rules, etc) are stored in Redis.

There is also a [dashboard](./dashboard) and [api](./api) provided for easy usage.

## Features
* Dashboard & API
* Analytics & Logging  - Powered by [ClickHouse](https://clickhouse.com/)
  * Amount of traffic used
  * Commonly visited paths
  * User agent parsing
  * Request logging
* Edge Caching
  * Byte range caching  - Videos or large files
  * Sorted query string
  * Respect origin cache headers
  * Bypass edge cache
  * Purge cache - Supports wildcard paths
* Edge SSL
  * Automatic SSL via Let's Encrypt
  * Custom SSL certificates
  * SSL termination
* Security
  * Enforce HTTPS
  * Hot linking protection
  * CORS headers
  * GeoIP - Set in special headers `x-request-country`
  * Edge Rules
    * Block by GeoIP

## Use Cases
* Running your own CDN network
* Dynamically serve client websites like Netlify and Vercel

## Components
* Dashboard
* Lua module - `/src/lua/` (Install in your lua lib path)
* Nginx Configuration - `/src/nginx/nginx.conf`

## Upcoming Features
* Web Application Firewall with ModSecurity ruleset support
* Rate limiting
* Captcha (Geetest, hCaptcha, ReCaptcha)
* Javascript bot verification