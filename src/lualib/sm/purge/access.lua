-- Load essential libraries
local config = require 'sm.config'
local redis = require 'sm.utils.redis'
local config_fetcher = require 'sm.utils.config_fetcher'
local cache = require 'sm.utils.cache'

-- Ngx variables
local host = ngx.var.host
local ngx_unescape_uri = ngx.unescape_uri
local request_uri = ngx_unescape_uri(ngx.var.request_uri)
local request_uri_args = ngx.req.get_uri_args(100)

-- Connect to Redis
local ok, err = redis.connect(config['redis']['host'], config['redis']['port'], config['redis']['timeout'])

if not ok then
    ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
end

-- Grab hostname config from cache
local hostname, hit_level, err = config_fetcher.hostname(redis, host)

if not hostname then
    -- Always close Redis
    redis.close()

    -- Hostname not found
    ngx.exit(ngx.HTTP_NOT_FOUND)
end

-- Lookup zone config from cache
local config, hit_level, err = config_fetcher.zone(redis, hostname['key'])

-- Config not found for website
if not config then
    -- Always close Redis
    redis.close()

    -- Zone not found
    ngx.exit(ngx.HTTP_NOT_FOUND)
end

local cache_key, err = cache.create_key(hostname['key'], request_uri, request_uri_args, config['cache_query'])

if not cache_key then
    -- Always close Redis
    redis.close()

    -- Error creating cache key
    ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
end

-- Set cache key
ngx.ctx.cache_key = cache_key