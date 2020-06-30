-- Load essential libraries
local resty_lock = require 'resty.lock'
local internal_cache = require 'sm.utils.internal_cache'
local vault = require 'sm.utils.vault'
local lemur = require 'sm.utils.lemur'

-- Variables
local log = ngx.log
local ERR = ngx.ERR
local shared = ngx.shared
local setmetatable = setmetatable
local token_expired = false
local retries = 3

local M = {}
local mt = { __index = M }

-- Initiate cache config
function M.new(ssl_config, internal_config, lemur_config)
	-- Sanity checks
	local dict = shared[ssl_config['cache_dict']]
	if not dict then
		return nil, 'Shared dictionary "' .. ssl_config['cache_dict'] .. '" not found'
	end

	local lock = shared[ssl_config['lock_dict']]
	if not lock then
		return nil, 'Shared dictionary "' .. ssl_config['lock_dict'] .. '" not found'
	end

	if type(ssl_config['expiration']) ~= 'number' then
		return nil, 'Expiration must be a number'
	end

	-- Initiate internal cache
	local internalc, err = internal_cache.new(internal_config)
	if err then
		return nil, 'Error occurred while initializing internal cache: ' .. err
	end

	-- Initate Lemur
	local lemurc, err = lemur.new(lemur_config)
	if not lemurc then
		-- Fallback to default cert
		return nil, 'Failed to initialize Lemur instance: ' .. err
	end

	local self = {
		cache = dict,
		lock = ssl_config['lock_dict'],
		expiration = ssl_config['expiration'],
		internal_cache = internalc,
		lemur = lemurc
	}

	return setmetatable(self, mt)
end

-- Unlock and return values
local function unlock_and_ret(lock, val, cache_status, err)
	local ok, lerr = lock:unlock()

	if not ok and lerr ~= 'unlocked' then
		return nil, nil, 'Failed to unlock callback: ' .. lerr
	end

	return val, cache_status, err
end

local function lock(lock, cache, key)
	-- Create new lock
	local lock, err = resty_lock:new(lock)

	if not lock then
		return nil, 'Failed to create lock: ' .. err
	end

	local elapsed, lerr = lock:lock(key)

	if not elapsed and lerr ~= 'timeout' then
		return nil, 'Failed to acquire lock: ' .. lerr
	end

	-- Check if another worker has populated cache
	local val, err = cache:get(key)

	if err then
		return unlock_and_ret(lock, nil, nil, err)
	elseif val then
		return unlock_and_ret(lock, val, 'HIT', nil)
	end

	return lock, nil
end

local function get_lemur_token(internal_cache, server_id)
	local token, cache_status, err

	-- If token is expired we force update
	if token_expired == true then
		ngx.log(ngx.OK, 'token expired, force updating')

		token, cache_status, err = internal_cache:update('lemur', vault.get, 'edge/data/' .. server_id .. '/lemur', 'token')

		ngx.log(ngx.OK, 'new token is ', token)
	else
		token, cache_status, err = internal_cache:get('lemur', vault.get, 'edge/data/' .. server_id .. '/lemur', 'token')
	end

	if err then
		return nil, nil, err
	end

	return token, cache_status, nil
end


-- Get secret from cache or perform callback
function M:get(key, server_id, item, lemur_path)
	-- Key sanity check
	if type(key) ~= 'string' then
		return nil, nil, 'Key must be a string'
	end

	if type(lemur_path) ~= 'string' then
		return nil, nil, 'Lemur path must be a string'
	end

	if type(item) ~= 'string' or (item ~= 'certificate' and item ~= 'private key') then
		return nil, nil, 'Item must be a string and equal to either "certificate" or "private key"'
	end

	-- Look up key in cache
	local val, err = self.cache:get(key)
	if val then
		ngx.log(ngx.OK, item, ' found in cache')
		return val, 'HIT', nil
	end

	-- Create new lock
	local lock, err = lock(self.lock, self.cache, key)
	if not lock then
		return nil, nil, err
	end

	-- Reset token expired variable
	token_expired = false
	ngx.log(ngx.OK, item, ' not in cache')

	for i = 1, retries do
		-- Get Lemur token
		lemur_token, cache_status, err = get_lemur_token(self.internal_cache, server_id)
		if not lemur_token then
			-- Log error, but do not fallback
			log(ERR, '[SSL] [', i, '/', retries, '] Error occurred while fetching Lemur token from cache: ', err)
			goto continue
		end

		-- Get item from Lemur
		val, token_expired, err = self.lemur:get(lemur_token, lemur_path)
		if err then
			-- Log error, but do not fallback
			log(ERR, '[SSL] [', i, '/', retries, '] Failed to get ', item, ' from Lemur: ', err)
			goto continue
		end

		-- Item acquired, extract from response body and break out
		if val then
			if item == 'certificate' then
				val = val.body
			else
				val = val.key
			end
			break 
		end

		::continue::
	end

	-- Return if no certificate
	if not val then
		return nil, 'Failed to acquire ' .. item ..'. ' .. retries ..' attempts failed!'
	end

	-- Set callback value in cache
	local ok, err = self.cache:set(key, val, self.expiration)
	if err then
		return unlock_and_ret(lock, nil, nil, err)
	end

	-- Return new value
	return unlock_and_ret(lock, val, 'EXPIRED', nil)
end

return M