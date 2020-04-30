local M = {}

function M.load(config)
	local _M = {}

	local exit = require('sm.utils.exit').load(config)
	local mongo = require('resty-mongol')

	-- Initialize database and collection
	local function init()
		if not _M.conn then
			local conn = mongo()

			conn:set_timeout(config['mongodb']['timeout'])

			local ok, err = conn:connect(config['mongodb']['host'], config['mongodb']['port'])

			if not ok then
				exit.error('Mongodb Error: [Init] ' .. err)
			end

			local db  = conn:new_db_handle(config['mongodb']['database'])
			local col = db:get_col(config['mongodb']['collection'])

			if not db or not col then
				exit.error('Mongodb Error: [Init] ' .. err)
			end

			_M.conn = col
		end

		return
	end

	-- Get record
	function _M.get(query)
		init()

		local doc = _M.conn:find_one(query)

		return doc
	end

	return _M
end

return M