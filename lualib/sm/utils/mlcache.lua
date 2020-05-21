local M = {}
local mt = {}

local mlcache = require 'resty.mlcache'

-- Initialize cache
function M.init(config)
	if type(config['number_of_instances']) ~= 'number' or config['number_of_instances'] < 1 then
		return nil, '[Mlcache] Number of instances must be a number and greater or equal to 1'
	end

	local mlcaches = {}
	local shm_names = {}

	-- Create 2 instances of mlcache per worker
	for i = 1, config['number_of_instances'] do
		local name = config['name'] .. '_' .. i
		local hit = config['dict_hit'] .. '_' .. i
		local miss = config['dict_miss'] .. '_' .. i

		-- Check if tables exist
		if not ngx.shared[hit] then
			return nil, '[Mlcache] Shared dictionary "' .. hit .. '" not found'
		end

		if not ngx.shared[miss] then
			return nil, '[Mlcache] Shared dictionary "' .. miss .. '" not found'
		end

		if ngx.shared[name] then
			local cache, err = mlcache.new(name, hit, {
				shm_miss = miss,
				shm_lock = config['dict_lock'], -- Mlcache instances can share the same lock dict
				lru_size = config['lru_size'],
				ttl = config['ttl'],
				neg_ttl = config['neg_ttl'],
				resurrect_ttl = config['resurrect_ttl']
			})

			if not cache then
				return nil, '[Mlcache] Failed to initialize cache "' .. name .. '": ' .. err
			end

			-- logger.debug('[Mlcache] Cache '' .. name .. '' successfully initialized')

			mlcaches[i] = cache
			shm_names[i] = name
		else
			return nil,'[Mlcache] Failed to initialize mlcache instance "' .. name .. '"'
		end
	end 

	local self = {
		mlcache = mlcaches[1],
		mlcaches = mlcaches,
		shm_names = shm_names
	}

	M.cache = mlcaches[1]

	setmetatable(self, mt)

	return true, nil
end


-- Fetch from cache with key
function M.get_config(key, callback)
	if type(key) ~= 'string' then
		return nil, nil, '[Mlcache] Key must be a string'
	end

	-- Get cache from mlcache
	local value, err, hit_level = M.cache:get(key, nil, callback, key)

	-- if err then
	-- 	return nil, nil, '[Mlcache] Failed to retrieve cache from callback: ' .. err
	-- end

	return value, hit_level, err
end

-- Set cache with key
function M.set(key, value)
	if type(key) ~= 'string' then
		return nil, '[Mlcache] Key must be a string'
	end

	-- Write function to delegate websites into different cache
	local shm_name = self.shm_names[1]

	-- Prepare
	return ngx.shared[shm_name]:safe_set(shm_name .. key, value)
end

-- See if cache is present
function M.peek(key)
	if type(key) ~= 'string' then
		return nil, '[Mlcache] Key must be a string'
	end

	local ttl, err, value = self.mlcache:peek(key)

	if err then
		return nil, err
	end

	return ttl, nil, value
end

return M