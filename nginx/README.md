# Nginx Module
The core of LightPath uses Openresty, a precompiled Nginx web server with Lua support. LightPath uses Lua to provide
many of its features.

## Scripts
Openresty allows you to hook into the lifecycle of an request. LightPath hooks into the following:

* Access
* Header
* Error