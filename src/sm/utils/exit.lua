local template = require 'resty.template'

local log = ngx.log
local ERR = ngx.ERR
local OK = ngx.OK

local M = {}

-- Exit Nginx with status and exit code
local function clean_exit(html, variables, status, code)
	-- Set default headers
	ngx.header['Content-Type'] = 'text/html'

	-- Set status code
	ngx.status = status

	-- Render template
	template.render(html, variables)

	-- Exit nginx
	ngx.exit(code)
end

-- Exit nginx instance
function M.nginx_abort()
	ngx.exit(ERR)
end

-- Configuration missing
function M.config(ip, request_id)
	return clean_exit('config.html', nil, 500, ngx.HTTP_INTERNAL_SERVER_ERROR)
end

-- Internal error
function M.error(ip, request_id)
	return clean_exit('500.html', nil, 500, ngx.HTTP_INTERNAL_SERVER_ERROR)
end

-- Block request due to rule
function M.rule_block(ip, request_id)
	return clean_exit('block.html', nil, 403, ngx.HTTP_FORBIDDEN)
end

-- Debug exit
function M.debug(message)
	return clean_exit(message, 200, ngx.OK)
end

return M