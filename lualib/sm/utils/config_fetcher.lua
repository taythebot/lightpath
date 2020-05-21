local md5 = require 'resty.md5'
local str = require 'resty.string'
local mlcache = require 'sm.utils.mlcache'

local M = {}

-- Grab hostname config
function M.hostname(redis, hostname)
	local md5 = md5:new()

	if not md5 then
		return nil, nil, 'Failed to initialize MD5 instance'
	end

	local ok = md5:update(hostname)

	if not ok then
		return nil, nil, 'Failed to update MD5 object'
	end

	local digest = md5:final()

	if not digest then
		return nil, nil, 'Failed to finialize MD5 object'
	end

	local key = str.to_hex(digest)

	if not key then
		return nil, nil, 'Failed to compute MD5 key'
	end

	local hostname, hitlevel, err = mlcache.get_config(key, redis.hgetall)

	if not hostname then
		return nil, nil, err
	end

	return hostname, hitlevel, err
end

-- Grab rule
function M.rule(redis, zone, target, value)
	local md5 = md5:new()

	if not md5 then
		return nil, nil, nil, 'Failed to initialize MD5 instance'
	end

	local ok = md5:update(zone)

	if not ok then
		return nil, nil, nil, 'Failed to update MD5 object'
	end

	local ok = md5:update(target)

	if not ok then
		return nil, nil, nil, 'Failed to update MD5 object'
	end

	local ok = md5:update(value)

	if not ok then
		return nil, nil, nil, 'Failed to update MD5 object'
	end

	local digest = md5:final()

	if not digest then
		return nil, nil, nil, 'Failed to finialize MD5 object'
	end

	local key = str.to_hex(digest)

	if not key then
		return nil, nil, nil, 'Failed to compute MD5 key'
	end

	local rule, hitlevel, err = mlcache.get_config(key, redis.get)

	if err then
		return nil, nil, nil, err
	end

	return key, rule, hitlevel, err
end

-- Grab zone config
function M.zone(redis, key)
	-- Grab config from mlcache
	local config, hit_level, err = mlcache.get_config(key, redis.hgetall)

	-- Handle errors
	if not config then
		return nil, nil, err
	end

	return config, hit_level, nil
end

return M