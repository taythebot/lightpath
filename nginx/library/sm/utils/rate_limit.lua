local M = {}

function M.load(config)
	local _M = {}

	local exit = require('sm.utils.exit').load(config)
	local memcached = require('sm.utils.memcached').load(config)
	local limit_handler = require('resty.limit.count')
	
	-- Initiate rate limit table
	local function init(storage_table, requests, window)
		local limit, err = limit_handler.new(storage_table, requests, window)

		if not limit then
			exit.error('Rate Limit Error: [INIT] ' .. err)
		end

		return limit
	end

	-- Check rate limit is applied to ip and host
	function _M.check(key)
		local record = memcached.get(key)

		if not record then
			return true
		else
			return false
		end
	end

	-- Execute rate limit
	function _M.execute(key, requests, window, cooldown)
		local limit = init(config['rate_limit_storage'], requests, window)

		local delay, err = limit:incoming(key, true)

		if not delay then
			if err == 'rejected' then
				local check = _M.check(key)

				if not check then
					local ok = memcached.set(key, 'true', cooldown)

					if not ok then
						exit.error('Rate Limit Error: ' .. err)
					end
				end

				exit.rate_limit()
			else
				exit.error('Rate Limit Error: ' .. err)
			end
		end

		return
	end

	return _M
end

return M