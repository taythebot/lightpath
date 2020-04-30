local _M = {}

function _M.load(config)
	local exit = require('sm.utils.exit').load(config)
	local redis = require('sm.utils.redis').load(config)

	-- Fetch document
	local doc = redis.get(ngx.var.host)

	-- No document found
	if not doc then
		exit.config()
	end

	-- Merge configs
	for v = 1, #doc, 2 do
		config[doc[v]] = doc[v+1]
	end

	return config
end

return _M