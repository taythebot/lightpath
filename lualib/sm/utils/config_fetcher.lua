local mlcache = require 'sm.utils.mlcache'

local M = {}

function M.load(redis, key)
	-- Grab config from mlcache
	local config, hit_level, err = mlcache.get_config(key, redis.hgetall, key)

	-- Handle errors
	if not config then
		return nil, nil, err
	end

	return config, hit_level, nil
end

return M