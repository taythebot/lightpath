local M = {}

function M.run(global_config)
	-- Load essential libraries
	local exit = require 'sm.utils.exit'
	local redis = require 'sm.utils.redis'
	local config_fetcher = require 'sm.utils.config_fetcher'
	local blacklist = require 'sm.utils.blacklist'
	local cache = require 'sm.utils.cache'

	local ngx_unescape_uri = ngx.unescape_uri

	local host = ngx.var.host
	local remote_addr = ngx.var.remote_addr
	local request_id = ngx.var.request_id
	local request_country = ngx.var.geoip2_data_country_code

	-- Connect to Redis
	local ok, err = redis.connect(global_config['redis']['host'], global_config['redis']['port'], global_config['redis']['timeout'])

	if not ok then
		exit.error(remote_addr, request_id, '[Service][Redis] Failed to connect to Redis: ' .. err)
	end
	
	-- Grab config from cache
	local config, hit_level, err = config_fetcher.load(redis, host)

	-- Config not found for website
	if not config then
		-- Always close Redis
		redis.close()

		-- Show error to user
		exit.config(remote_addr, request_id)
	end

	-- Assign local variables from website config
	local request_uri = ngx_unescape_uri(ngx.var.request_uri)
	local request_uri_args = ngx.req.get_uri_args(100)
	local https = config['https'] or '0'
	local cache_enabled = config['cache_enabled'] or '1'
	local cache_ttl = config['cache_ttl']
	--  Cache Query Options: 0 = same, 1 = ignore, 2 = sorted 
	local cache_query = config['cache_query'] or '2' 
	local backend_https = config['backend_https']
	local backend =  config['backend']
	local backend_port = config['backend_port']
	local ip_blacklist = config['ip_blacklist']
	local country_blacklist = config['country_blacklist']
	local compression = config['compression']
	-- Image copmression: 0 = none, 1 = loseless
	-- local image_compression = config['image_compression'] or '0'

	-- Brotli compression settings
	if compression ~= 'br' then
		ngx.var.brotli_ok = false
	end

	-- Image compression settings
	-- if image_compression == '0' then
	-- 	ngx.var.image_compress = true
	-- end

	-- Handle HTTPS requirements
	if https == '1' then
		if ngx.var.scheme == 'http' then
			-- Always close Redis
			redis.close()

			-- Redirect to HTTPS
			return ngx.redirect('https://' .. host .. request_uri)
		end
	end

	-- IP Blacklist
	if ip_blacklist then
		-- Check blacklist against user ip address
		local ok, err = blacklist.check_list(ip_blacklist, remote_addr)

		if err then
			-- Always close Redis
			redis.close()

			-- Show error to user
			exit.error(remote_addr, request_id, '[Service] Error occurred while executing ip blacklist: ' .. err)
		end
		
		if not ok then
			ngx.var.reason = 'IP blacklist'

			-- Always close Redis
			redis.close()

			-- Block request
			exit.block(remote_addr, request_id)
		end
	end

	-- Country Blacklist
	if country_blacklist then
		-- Check blacklist against user ip address
		local ok, err = blacklist.check_list(country_blacklist, request_country)

		if err then
			-- Always close Redis
			redis.close()

			-- Show error to user
			exit.error(remote_addr, request_id, '[Service] Error occurred while executing country blacklist: ' .. err)
		end
		
		if not ok then
			ngx.var.reason = 'Country blacklist'

			-- Always close Redis
			redis.close()

			-- Block request
			exit.block(remote_addr, request_id)
		end
	end

	-- Handle cache, let users disable cache in the future for WAF and DDoS protection
	if cache_enabled == '1' then
		-- Prepare master cache key
		local key, err = cache.prepare_key(backend, backend_port, request_uri, request_uri_args, cache_query)

		if not key then
			-- Always close Redis
			redis.close()

			-- Show error to user
			exit.error(remote_addr, request_id, '[Service][Cache] Failed to create cache key: ' .. err)
		end

		-- Fetch item from cache or origin
		local ok, err = cache.get(redis, key, backend_https, backend, backend_port, request_uri, cache_ttl)

		if not ok then
			-- Always close Redis
			redis.close()

			-- Show 500 error to user
			exit.error(remote_addr, request_id, '[Service][Cache] Failed to fetch item from cache: ' .. err)
		end
	end

	-- Always close Redis
	redis.close()

	-- Show error as last resort
	exit.error(remote_addr, request_id, '[Service] No action was taken. Reached end of service.')
	
	return _M
end

return M