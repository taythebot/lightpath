-- Load libraries
local exit = require "sm.utils.exit"
local global_config = require "sm.config"
local redis = require "sm.utils.redis"
local config_fetcher = require "sm.utils.config_fetcher"
local cache = require "sm.utils.cache"
local ngx_re = require "ngx.re"
local random = require "sm.utils.random"
local error = require "sm.utils.error"

-- Native functions
local log = ngx.log
local ERR = ngx.ERR
local os_getenv = os.getenv
local ngx_redirect = ngx.redirect
local ngx_re_match = ngx.re.match
local ngx_unescape_uri = ngx.unescape_uri
local ngx_req_get_headers = ngx.req.get_headers
local VERSION = _VERSION

-- Request variables
local host = ngx.var.host
local remote_addr = ngx.var.remote_addr
local request_id = ngx.var.request_id
local request_country = ngx.var.geoip2_data_country_code
local request_asn = ngx.var.geoip2_data_asn_number
local request_uri = ngx_unescape_uri(ngx.var.request_uri)
local request_uri_args = ngx.req.get_uri_args(100)
local request_method = ngx.var.request_method
local request_scheme = ngx.var.scheme
local zone_id

-- Random seed
random.seed()

-- Local function to exit
local function clean_exit(type, err)
    -- Log error if any
    if err then
        log(ERR, err)
    end

    -- Always close redis
    redis.close()

    -- Perform exit
    return exit[type](remote_addr, request_id)
end

-- TODO: move to config_fetcher.lua
-- Local function to lookup rules and take action
local function rule_lookup(target, value)
    local rule_id, action, hit_level, err = config_fetcher.rule(redis, zone_id, target, value)
    if err then
        return nil, nil, err
    end

    return action, rule_id
end

-- Connect to Redis
local ok, err = redis.connect(global_config["redis"])
if not ok then
    return clean_exit("error", err)
end

-- Grab hostname config from cache
local hostname, hit_level, err = config_fetcher.hostname(redis, host)
if not hostname then
    return clean_exit("config")
elseif err then
    return clean_exit("error", err)
end

-- Enforce HTTPS
if hostname["https"] == "true" and request_scheme == "http" then
    -- Always close Redis
    redis.close()

    -- Redirect to HTTPS
    return ngx_redirect("https://" .. host .. request_uri)
end

-- Store zone id for global reference
zone_id = hostname["key"]

-- Wildcard referral firewall rule
local action, rule_id, err = rule_lookup("referral", "*")
if action == "block" then
    ngx.ctx.reason = rule_id
    return exit.rule_block(remote_addr, request_id)
elseif err then
    return clean_exit("error", err)
end

-- Execute only if referral header is present
local referral = ngx_req_get_headers()["Referer"]
if referral then
    -- Parse host out of referral
    referral = ngx_re_match(referral, "^(([^:/?#]+):)?(//([^/?#]*))?([^?#]*)(\\?([^#]*))?(#(.*))?")

    -- Referral firewall rule
    action, rule_id, err = rule_lookup("referral", parsed[4])
    if err then
        return clean_exit(err, "error")
    elseif action == "block" then
        ngx.ctx.reason = rule_id
        return exit.clean_exit(err, "rule_block")
    end
end

-- IP firewall rule
action, rule_id, err = rule_lookup("ip", remote_addr .. "/32")
if err then
    return clean_exit(err, "error")
elseif action == "block" then
    ngx.ctx.reason = rule_id

    return exit.clean_exit(err, "rule_block")
end

-- ASN firewall rule
action, rule_id, err = rule_lookup("asn", request_asn)
if err then
    return clean_exit(err, "error")
elseif action == "block" then
    ngx.ctx.reason = rule_id

    return exit.clean_exit(err, "rule_block")
end

-- Country firewall rule
action, rule_id, err = rule_lookup("country", request_country)
if err then
    return clean_exit(err, "error")
elseif action == "block" then
    ngx.ctx.reason = rule_id

    return exit.clean_exit(err, "rule_block")
end

-- Fetch zone config
local config, hit_level, err = config_fetcher.zone(redis, zone_id)
if not config then
    return exit.clean_exit(err, 'config')
end

-- Cache settings
if config["cache_enabled"] == "1" then
    -- Compute cache key
    local cache_key = cache.create_key(zone_id, request_uri, request_uri_args, config["cache_query"])
    if not cache_key then
        return exit.clean_exit(error('Failed to create cache key'), 'error')
    end

    -- Set cache variables
    ngx.var.cache_zone = "global_cache"
    ngx.var.cache_key = cache_key

    -- Set cache TTL
    if config["cache_ttl"] == "0" then
        -- Respect origin cache-control headers
        ngx.var.cache_ttl = "Origin"
    else
        -- Ignore cache-control headers
        ngx.var.cache_ttl = config["cache_ttl"]
    end
end

-- Set Nginx variables
ngx.ctx.strip_cookies = config["strip_cookies"]
ngx.ctx.cors = config["cors"]

if config["backend_https"] == "0" then
    ngx.var.backend_protocol = "http://"
end

ngx.ctx.backend_host = config["backend_host"]
ngx.ctx.backend_port = config["backend_port"]
ngx.ctx.zone_id = zone_id

-- Always close Redis
redis.close()
