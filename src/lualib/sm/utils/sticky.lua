local M = {}

function M.load(config)
	local _M = {}

	local exit = require('sm.utils.exit').load(config)
	local cookie = require('sm.utils.cookie').load(config)
	local payload = require('sm.utils.payload').load(config)

	-- Check for sticky session
	function _M.check(sticky_name)
		local session = cookie.get(sticky_name)

		if session then
			return true
		else
			return false
		end
	end

	-- Set sticky session
	function _M.set(sticky_name, payload, website)
		cookie.set({
			key = sticky_name,
			value = payload,
			path = '/',
			domain = '.' .. website,
			secure = false,
			httponly = true,
			samesite = 'strict'
		})

		return
	end

	-- Verify sticky session
	function _M.verify(sticky_name, uid)
		local sticky = cookie.get(sticky_name)

		if sticky == uid then
			return true
		else
			return false
		end
	end

	-- Remove sticky session
	function _M.remove(sticky_name, website)
		-- Unset pass cookie
		cookie.set({
			key = sticky_name,
			value = 'expired',
			domain = '.' .. website,
			expires = 'Thu, Jan 01 1970 00:00:00 UTC'
		})
	end

	return _M
end

return M