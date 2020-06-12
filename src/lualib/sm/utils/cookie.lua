local M = {}

function M.load(config)
	local _M = {}

	local exit = require('sm.utils.exit').load(config)
	local cookie_handler = require('resty.cookie')

	-- Initiate cookie handler
	local function init()
		if not _M.cookie then
			local cookie, err = cookie_handler:new()

			if not cookie then
				exit.error('Cookie Error: [INIT] ' .. err)
			end

			_M.cookie = cookie
		end

		return
	end

	-- Get cookie
	function _M.get(key)
		init()

		local field = _M.cookie:get(key)

		return field
	end

	-- Set cookie
	function _M.set(value)
		init()

		local ok, err = _M.cookie:set(value)

		if not ok then
			exit.error('Cookie Error: ' .. err)
		end

		return
	end

	return _M
end

return M