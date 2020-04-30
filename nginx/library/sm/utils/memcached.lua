local M = {}

function M.load(config)
	local _M = {}

	local exit = require('sm.utils.exit').load(config)
	local shdict_simple = require('resty.shdict.simple')
	local shdict_memc = require('resty.memcached.shdict')

	-- Initiate memcached handler
	local function init()
		if not _M.memc_fetch or _M.memc_store then
			local meta_shdict_set, meta_shdict_get = 
			shdict_simple.gen_shdict_methods{
				dict_name = 'shdict_shared_table',
				debug_logger = exit.error,
				error_logger = exit.error,
				positive_ttl = 1000,
				negative_ttl = 2000,
				max_tries = 1,
			}

			local memc_fetch, memc_store =
			shdict_memc.gen_memc_methods{
				tag = config['server']['name'],
				debug_logger = exit.error,
				warn_logger = exit.error,
				error_logger = exit.error,
				locks_shdict_name = 'memcached_shared_table',
				shdict_set = meta_shdict_set,
				shdict_get = meta_shdict_get,
				disable_shdict = false,
				memc_host = config['memcached']['host'],
				memc_port = config['memcached']['port'],
				memc_timeout = config['memcached']['timeout'],
				memc_conn_pool_size = 5,
				memc_fetch_retries = 2,
				memc_fetch_retry_delay = 100,
				memc_conn_max_idle_time = 10 * 1000,
				memc_store_retries = 2,
				memc_store_retry_delay = 100,
				store_ttl = 1,
			}

			_M.memc_fetch = memc_fetch
			_M.memc_store = memc_store

		end

		return
	end

	-- Set record
	function _M.get(key)
		init()

		local value = _M.memc_fetch(ngx.ctx, key)

		return value
	end

	-- Get record
	function _M.set(key, value, cooldown)
		init()

		local ok, err = _M.memc_store(ngx.ctx, key, value, cooldown)
		
		if not ok then
			exit.error('Memcached Error: ' .. err)
		end

		return
	end

	-- Initiate memcached handler
	-- local function init()
	-- 	if not _M.conn then
	-- 		local conn, err = memcached:new()

	-- 		conn:set_timeout(config['memcached']['timeout'])

	-- 		local ok, err = conn:connect(config['memcached']['host'], config['memcached']['port'])

	-- 		if not ok then
	-- 			exit.error('Memcached Error: [Init] ' .. err)
	-- 		end

	-- 		_M.conn = conn
	-- 	end

	-- 	return
	-- end

	return _M
end

return M