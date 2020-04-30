local redis = require 'resty.redis'

local M = {}

-- Connect to Redis
function M.connect(host, port, timeout)
	local redis = redis:new()

	redis:set_timeout(timeout)

	local ok, err = redis:connect(host, port)

	if not ok then
		return nil, err
	end

	M.redis = redis

	return true, nil
end

-- Close connection
function M.close()
	local redis = M.redis

	if redis then
		local ok, err = redis:keepalive(10000, 100)

		if not ok then
			return nil, err
		end
	end
end

-- Get value
function M.get(key, table)
	local redis = M.redis

	local res, err = redis:get(key, table)

	if not res then
		return nil, err
	end

	return res
end

-- Get all hash keys
function M.hgetall(key)
	local final = {}

	local redis = M.redis

	local res, err = redis:hgetall(key)

	if not res then
		return nil, 'Error occurred while executing command "hgetall": ' .. err
	elseif next(res) == nil then
		return nil, 'Error occurred while executing command "hgetall": Key not found'
	end

	-- Reconstruct into table
	for v = 1, #res, 2 do
		final[res[v]] = res[v+1]
	end

	return final
end

-- Set hash keys
function M.hmset(key, values)
	local redis = M.redis

	local ok, err = redis:hmset(key, values)

	if not ok then
		return nil, 'Error occurred while executing command "hmset": ' .. err
	end

	return true, nil
end

-- Set key
function M.set(key, value)
	local redis = M.redis

	local ok, err = redis:set(key, value)

	if not ok then
		return nil, 'Error occurred while executing command "set": ' .. err
	end

	return true, nil
end

-- Set key expiry
function M.expire(key, ttl)
	local redis = M.redis

	local ok, err = redis:expire(key, ttl)

	return true, nil
end

-- Push element into list
function M.lpush(key, value)
	local redis = M.redis

	local ok, err = redis:lpush(key, value)

	if not ok then
		return nil, 'Error occurred while executing command "lpush": ' .. err
	end

	return true, nil
end


return M