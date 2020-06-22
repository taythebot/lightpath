local resty_lock = require 'resty.lock'
local signature = require 'sm.purge.utils.signature'

local shared = ngx.shared
local setmetatable = setmetatable
local xpcall = xpcall
local traceback = debug.traceback
local tostring = tostring

local M = {}
local _M = {}

-- Initiate cache config
function M.init(config, server_id)
	-- Sanity checks
	local dict = shared[config['cache_dict']]

	if not dict then
		return nil, 'Shared dictionary "' .. config['cache_dict'] .. '" not found'
	end

	local lock = shared[config['lock_dict']]

	if not lock then
		return nil, 'Shared dictionary "' .. config['lock_dict'] .. '" not found'
	end

	if type(server_id) ~= 'string' then
		return nil, 'Server ID must be a string'
	end

	_M.cache, _M.lock, _M.expiration, _M.server_id = dict, config['lock_dict'], config['expiration'], server_id

	return true, nil
end

-- Unlock and return values
local function unlock_and_ret(lock, val, cache_status, err)
	-- Unlock if lock is present
	if lock ~= nil then
		local ok, lerr = lock:unlock()

		if not ok and lerr ~= 'unlocked' then
			return nil, nil, nil, 'Failed to unlock callback: ' .. lerr
		end
	end

	-- Return early if no val
	if not val then
		return nil, nil, cache_status, err
	end

	-- Parse value
	local secret, signature = val:match('([^,]+),([^,]+)')

	if not secret then
		return nil, nil, cache_status, 'Failed to parse secret from cache'
	elseif not signature then
		return nil, nil, cache_status, 'Failed to parse signature from cache'
	end

	return secret, signature, cache_status, err
end

-- Get secret from cache or perform callback
function M.get(key, cb, ...)
	-- Key sanity check
	if type(key) ~= 'string' then
		return nil, 'Key must be a string'
	end

	-- Look up key in cache
	local val, err = _M.cache:get(key)

	-- Return key if found
	if val then
		return unlock_and_ret(nil, val, 'HIT', nil)
	end

	-- Create new lock
	local lock, err = resty_lock:new(_M.lock)

	if not lock then
		return nil, nil, 'Failed to create lock: ' .. err
	end

	local elapsed, lerr = lock:lock(key)

	if not elapsed and err ~= 'timeout' then
		return nil, nil, 'Failed to acquire lock: ' .. err
	end

	-- Check if another worker has populated cache
	local val, err = _M.cache:get(key)

	if err then
		return unlock_and_ret(lock, nil, nil, err)
	elseif val then
		return unlock_and_ret(lock, val, 'HIT', nil)
	end

	-- Perform callback
	local pok, perr, err = xpcall(cb, traceback, ...)

	if not pok then
		return unlock_and_ret(lock, nil, nil, 'Callback threw an error: ' .. tostring(perr))
	elseif err then
		return unlock_and_ret(lock, nil, nil, err)
	end

	-- Compute signature
	local signature, err = signature.compute(_M.server_id, perr)

	if not signature then
		return unlock_and_ret(lock, nil, nil, err)
	end

	-- Combine secret and signature
	local secret = perr .. ',' .. signature

	-- Set secret in cache
	local ok, err = _M.cache:set(key, secret, _M.expiration)

	if err then
		return unlock_and_ret(lock, nil, nil, err)
	end

	-- Return new value
	return unlock_and_ret(lock, secret, 'EXPIRED', nil)
end

-- Force update secret
function M.update(key, cb, ...)
	-- Create new lock
	local lock, err = resty_lock:new(_M.lock)

	if not lock then
		return nil, nil, 'Failed to create lock: ' .. err
	end

	local elapsed, lerr = lock:lock(key)

	if not elapsed and err ~= 'timeout' then
		return nil, nil, 'Failed to acquire lock: ' .. err
	end

	-- Perform callback
	local pok, perr, err = xpcall(cb, traceback, ...)

	if not pok then
		return unlock_and_ret(lock, nil, nil, 'Callback threw an error: ' .. tostring(perr))
	elseif err then
		return unlock_and_ret(lock, nil, nil, err)
	end

	-- Compute signature
	local signature, err = signature.compute(_M.server_id, perr)

	if not signature then
		return unlock_and_ret(lock, nil, nil, err)
	end

	-- Combine secret and signature
	local secret = perr .. ',' .. signature

	-- Set secret in cache
	local ok, err = _M.cache:set(key, secret, _M.expiration)

	if err then
		return unlock_and_ret(lock, nil, nil, err)
	end

	-- Return new value
	return unlock_and_ret(lock, secret, 'EXPIRED', nil)
end

return M