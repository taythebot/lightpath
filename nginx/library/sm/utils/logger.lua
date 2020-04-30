local M = {}

function M.load(config)
	local _M = {}
	
	local ngx_log = ngx.log
	local ngx_ERR = ngx.ERR

	-- Validate message
	local function validate_msg(message)
		if type(message) ~= 'string' and type(message) ~= 'number' then
			return false
		end
		return true
	end

	-- Log debug message
	function _M.debug(message)
		if (not validate_msg(message)) then
			return
		end

		if config.dev == true then
			ngx_log(ngx_ERR, "[SM - DEBUG] [" .. config['server']['name'] .. "] - " .. message)
		end
	end

	-- Log error message
	function _M.error(message)
		if (not validate_msg(message)) then
			return
		end

		ngx_log(ngx_ERR, "[SM - ERROR] [" .. config['server']['name'] .. "] - " .. message)
	end

	return _M
end

return M