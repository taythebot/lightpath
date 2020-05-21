local M = {}

function M.run(global_config)
	-- Load essential libraries
	local exit = require 'sm.utils.exit'
	local redis = require 'sm.utils.redis'
	local config_fetcher = require 'sm.utils.config_fetcher'
	local cache = require 'sm.utils.cache'

	local host = ngx.var.host
	local remote_addr = ngx.var.remote_addr
	local request_id = ngx.var.request_id
	local request_country = ngx.var.geoip2_data_country_code
	local request_asn = ngx.var.geoip2_data_asn_number
	
	local ngx_unescape_uri = ngx.unescape_uri
	local request_uri = ngx_unescape_uri(ngx.var.request_uri)
	local request_uri_args = ngx.req.get_uri_args(100)

	-- Connect to Redis
	local ok, err = redis.connect(global_config['redis']['host'], global_config['redis']['port'], global_config['redis']['timeout'])

	if not ok then
		exit.error(remote_addr, request_id, '[Service] Failed to connect to Redis: ' .. err)
	end

	-- Grab hostname config from cache
	local hostname, hit_level, err = config_fetcher.hostname(redis, host)
	
	if not hostname then
		redis.close()

		exit.config(remote_addr, request_id)
	end

	-- Handle HTTPS requirements
	if hostname['https'] == '1' and ngx.var.scheme == 'http' then
		-- Always close Redis
		redis.close()

		-- Redirect to HTTPS
		return ngx.redirect('https://' .. host .. request_uri)
	end

	local zone = hostname['key']

	-- Lookup ip firewall rule from cache
	local rule_id, ip_rule, hit_level, err = config_fetcher.rule(redis, zone, 'ip', remote_addr .. '/32')

	if err then
		-- Always close Redis
		redis.close()

		-- Show error to user
		exit.error(remote_addr, request_id, '[Service] Error occurred while looking up ip rule: ' .. err)
	end

	if ip_rule == 'block' then
		ngx.ctx.reason = rule_id

		-- Always close Redis
		redis.close()

		-- Block request
		exit.ip_block(remote_addr, request_id)
	end

	-- Lookup asn firewall rule from cache
	-- local rule_id, ip_rule, hit_level, err = config_fetcher.rule(redis, zone, 'asn', request_asn)

	-- if err then
	-- 	-- Always close Redis
	-- 	redis.close()

	-- 	-- Show error to user
	-- 	exit.error(remote_addr, request_id, '[Service] Error occurred while looking up asn rule: ' .. err)
	-- end

	-- if ip_rule == 'block' then
	-- 	ngx.ctx.reason = rule_id

	-- 	-- Always close Redis
	-- 	redis.close()

	-- 	-- Block request
	-- 	exit.ip_block(remote_addr, request_id)
	-- end

	-- Lookup country firewall rule from cache
	local rule_id, country_rule, hit_level, err = config_fetcher.rule(redis, zone, 'country', request_country)

	if err then
		-- Always close Redis
		redis.close()

		-- Show error to user
		exit.error(remote_addr, request_id, '[Service] Error occurred while looking up conutry rule: ' .. err)
	end

	if country_rule == 'block' then
		ngx.log(ngx.OK, 'country block')

		ngx.ctx.reason = rule_id

		-- Always close Redis
		redis.close()

		-- Block request
		exit.country_block(remote_addr, request_id)
	end

	-- Lookup zone config from cache
	local config, hit_level, err = config_fetcher.zone(redis, zone)

	-- Config not found for website
	if not config then
		-- Always close Redis
		redis.close()

		-- Show error to user
		exit.config(remote_addr, request_id)
	end

	-- Cache settings
	if config['cache_enabled'] == '1' then
		-- Compute cache key
		local cache_key, err = cache.prepare_key(zone, request_uri, request_uri_args, config['cache_query'])

		if not cache_key then
			-- Always close Redis
			redis.close()

			-- Show error to user
			exit.error(remote_addr, request_id, '[Service] Failed to compute cache key: ' .. err)
		end

		-- Set cache variables
		ngx.var.cache_zone = 'global_cache'
		ngx.var.cache_key = cache_key

		-- if config['cache_ttl'] == '0' then
		-- 	-- Respect origin cache-control headers
		-- 	ngx.var.cache_ttl = 'Origin'
		-- else
		-- 	-- Ignore cache-control headers
		-- 	ngx.var.cache_ttl = config['cache_ttl']
		-- end
		ngx.var.cache_ttl = 'Origin'
	end

	-- Always close Redis
	redis.close()

	-- Set final nginx variables
	ngx.ctx.strip_cookies  = config['strip_cookies']

	if config['backend_https'] == '1' then
		ngx.var.backend_protocol = 'https://'
	else
		ngx.var.backend_protocol = 'http://'
	end

	ngx.ctx.backend_host = config['backend_host']
	ngx.ctx.backend_port = config['backend_port']
	
	return _M
end

return M