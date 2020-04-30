local M = {}

function M.load(config)
	local _M = {}

	local exit = require('sm.utils.exit').load(config)
	local redis = require('resty.redis')
	local cjson = require('cjson')

	-- Initialize redis instance
	local function init()
		if not _M.conn then
			local conn = redis:new()

			conn:set_timeout(config['redis']['timeout'])

			local ok, err = conn:connect(config['redis']['host'], config['redis']['port'], config['redis']['table'])

			if not ok then
				exit.error('Redis Error: [Init] ' .. err)
			end

			_M.conn = conn
		end

		return
	end

	-- Get record
	function _M.get(key)
		init()

		local doc = _M.conn:hgetall(key)

		return doc
	end

	return _M
end

return M