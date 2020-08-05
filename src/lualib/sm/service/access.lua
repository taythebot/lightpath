-- Load essential libraries
local exit = require 'sm.utils.exit'
local global_config = require 'sm.config'
local redis = require 'sm.utils.redis'
local config_fetcher = require 'sm.utils.config_fetcher'
local cache = require 'sm.utils.cache'
local ngx_re = require 'ngx.re'

-- Variables
local host = ngx.var.host
local remote_addr = ngx.var.remote_addr
local request_id = ngx.var.request_id
local request_country = ngx.var.geoip2_data_country_code
local request_asn = ngx.var.geoip2_data_asn_number
local ngx_req_get_headers = ngx.req.get_headers	

local ngx_redirect = ngx.redirect
local ngx_re_match = ngx.re.match
local ngx_unescape_uri = ngx.unescape_uri
local request_uri = ngx_unescape_uri(ngx.var.request_uri)
local request_uri_args = ngx.req.get_uri_args(100)

-- Connect to Redis
local ok, err = redis.connect(global_config['redis'])
if not ok then
	return exit.error(remote_addr, request_id, '[Service] Failed to connect to Redis: ' .. err)
end

-- Grab hostname config from cache
local hostname, hit_level, err = config_fetcher.hostname(redis, host)
if not hostname then
	-- Always close Redis
	redis.close()

	-- Show error to user
	return exit.config(remote_addr, request_id)
end

-- Handle HTTPS requirements
if hostname['https'] == '1' and ngx.var.scheme == 'http' then
	-- Always close Redis
	redis.close()

	-- Redirect to HTTPS
	return ngx_redirect('https://' .. host .. request_uri)
end

local zone = hostname['key']

-- Look up wildcard block referral rule from cache
local global_rule_id, global_referral_rule, hit_level, err = config_fetcher.rule(redis, zone, 'referral', '*')
if err then
	-- Always close Redis
	redis.close()

	-- Show error to user
	return exit.error(remote_addr, request_id, '[Service] Error occurred while looking up global referral rule: ' .. err)
end

-- Check for referral header
local referral = ngx_req_get_headers()['Referer']
if referral then
	local host = ngx_re_match(referral, '^(([^:/?#]+):)?(//([^/?#]*))?([^?#]*)(\\?([^#]*))?(#(.*))?')

	-- Look up host referral rule from cache
	local rule_id, referral_rule, hit_level, err = config_fetcher.rule(redis, zone, 'referral', host[4])
	if err then
		-- Always close Redis
		redis.close()

		-- Show error to user
		return exit.error(remote_addr, request_id, '[Service] Error occurred while looking up allow referral rule: ' .. err)
	end

	-- Blocked by global rule and no rule found to allow
	if global_referral_rule == 'block' or referral_rule == 'block' then
		if referral_rule == nil then
			ngx.ctx.reason = global_rule_id
		else
			ngx.ctx.reason = rule_id
		end

		-- Always close Redis
		redis.close()

		-- Block request
		return exit.rule_block(remote_addr, request_id)
	end
elseif global_referral_rule == 'block' then
	-- Blocked because of global and no referer header to lookup specific rule
	ngx.ctx.reason = global_rule_id

	-- Always close Redis
	redis.close()

	-- Block request
	return exit.rule_block(remote_addr, request_id)
end

-- Lookup ip firewall rule from cache
local rule_id, ip_rule, hit_level, err = config_fetcher.rule(redis, zone, 'ip', remote_addr .. '/32')
if err then
	-- Always close Redis
	redis.close()

	-- Show error to user
	return exit.error(remote_addr, request_id, '[Service] Error occurred while looking up ip rule: ' .. err)
end

if ip_rule == 'block' then
	ngx.ctx.reason = rule_id

	-- Always close Redis
	redis.close()

	-- Block request
	return exit.rule_block(remote_addr, request_id)
end

-- Lookup asn firewall rule from cache
-- local rule_id, ip_rule, hit_level, err = config_fetcher.rule(redis, zone, 'asn', request_asn)

-- if err then
-- 	-- Always close Redis
-- 	redis.close()

-- 	-- Show error to user
-- 	return exit.error(remote_addr, request_id, '[Service] Error occurred while looking up asn rule: ' .. err)
-- end

-- if ip_rule == 'block' then
-- 	ngx.ctx.reason = rule_id

-- 	-- Always close Redis
-- 	redis.close()

-- 	-- Block request
-- 	return exit.rule_block(remote_addr, request_id)
-- end

-- Lookup country firewall rule from cache
local rule_id, country_rule, hit_level, err = config_fetcher.rule(redis, zone, 'country', request_country)
if err then
	-- Always close Redis
	redis.close()

	-- Show error to user
	return exit.error(remote_addr, request_id, '[Service] Error occurred while looking up conutry rule: ' .. err)
end

if country_rule == 'block' then
	ngx.log(ngx.OK, 'country block')

	ngx.ctx.reason = rule_id

	-- Always close Redis
	redis.close()

	-- Block request
	return exit.rule_block(remote_addr, request_id)
end

-- Lookup zone config from cache
local config, hit_level, err = config_fetcher.zone(redis, zone)
if not config then
	-- Always close Redis
	redis.close()

	-- Show error to user
	return exit.config(remote_addr, request_id)
end

-- Cache settings
if config['cache_enabled'] == '1' then
	-- Compute cache key
	local cache_key, err = cache.create_key(zone, request_uri, request_uri_args, config['cache_query'])
	if not cache_key then
		-- Always close Redis
		redis.close()

		-- Show error to user
		return exit.error(remote_addr, request_id, '[Service] Error occurred while creating cache key: ' .. err)
	end

	-- Set cache variables
	ngx.var.cache_zone = 'global_cache'
	ngx.var.cache_key = cache_key

	if config['cache_ttl'] == '0' then
		-- Respect origin cache-control headers
		ngx.var.cache_ttl = 'Origin'
	else
		-- Ignore cache-control headers
		ngx.var.cache_ttl = config['cache_ttl']
	end
end

-- Always close Redis
redis.close()

-- Set final nginx variables
ngx.ctx.strip_cookies = config['strip_cookies']
ngx.ctx.cors = config['cors']

if config['backend_https'] == '1' then
	ngx.var.backend_protocol = 'https://'
else
	ngx.var.backend_protocol = 'http://'
end

-- ngx.ctx.backend_host = config['backend_host']
-- ngx.ctx.backend_port = config['backend_port']
ngx.ctx.backend_host = '127.0.0.1'
ngx.ctx.backend_port = '8080'
ngx.ctx.zone_id = zone
