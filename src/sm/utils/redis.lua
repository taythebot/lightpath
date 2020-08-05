local redis = require 'resty.redis'

local M = {}
local _M = {}

-- Connect to Redis
function M.connect(config)
	-- Sanity checks
	if type(config['host']) ~= 'string' then
		return nil, 'Host must be a string'
	end

	if type(config['port']) ~= 'number' then
		return nil, 'Port must be a number'
	end

	if type(config['timeout']) ~= 'number' then
		return nil, 'Timeout must be a number'
	end

	local red = redis:new()

	red:set_timeout(timeout)

	local ok, err = red:connect(config['host'], config['port'])

	if not ok then
		return nil, err
	end

	_M.redis = red

	return true, nil
end

-- Close connection
function M.close()
	if _M.redis then
		local ok, err = _M.redis:keepalive(10000, 100)

		if not ok then
			return nil, err
		end
	end
end

-- Get value
function M.get(key)
	local res, err = _M.redis:get(key)

	if not res or res == ngx.null then
		return nil, err
	end

	return res
end

-- Get all hash keys
function M.hgetall(key)
	local final = {}

	local res, err = _M.redis:hgetall(key)

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
	local ok, err = _M.redis:hmset(key, values)

	if not ok then
		return nil, 'Error occurred while executing command "hmset": ' .. err
	end

	return true, nil
end

-- Set key
function M.set(key, value)
	local ok, err = _M.redis:set(key, value)

	if not ok then
		return nil, 'Error occurred while executing command "set": ' .. err
	end

	return true, nil
end

-- Set key expiry
function M.expire(key, ttl)
	local ok, err = _M.redis:expire(key, ttl)

	return true, nil
end

-- Push element into list
function M.lpush(key, value)
	local ok, err = _M.redis:lpush(key, value)

	if not ok then
		return nil, 'Error occurred while executing command "lpush": ' .. err
	end

	return true, nil
end


return M