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

-- Browser challenge
function M.browser_challenge(website, script)
	local html = template.render('challenge.html', { website = website, script = script })
	
	return clean_exit(html, 503, ngx.OK)
end

-- Captcha v2 challenge
function M.captcha_v2_challenge(mode, token)
	local html = template.render('captcha_v2_' .. mode .. '.html', { ip = remote_addr, request_id = request_id, token = token, site_key = config['captcha'][mode .. '_site_key'] })
	
	return clean_exit(html, 403, ngx.OK)
end

-- Configuration missing
function M.config(ip, request_id)
	return clean_exit('config.html', { ip = ip, request_id = request_id }, 500, ngx.HTTP_INTERNAL_SERVER_ERROR)
end

-- Internal error
function M.error(ip, request_id, message)
	if message then
		log(ERR, message)
	end

	return clean_exit('500.html', { ip = ip, request_id = request_id }, 500, ngx.HTTP_INTERNAL_SERVER_ERROR)
end

-- Rate limit block
function M.rate_limit()
	local html = template.render('429.html', { ip = remote_addr, request_id = request_id })
	
	return clean_exit(html, 429, ngx.OK)
end

-- Block request due to ip rule
function M.ip_block(ip, request_id)
	return clean_exit('ip_block.html', { ip = ip, request_id = request_id }, 403, ngx.HTTP_FORBIDDEN)
end

-- Block request due to country rule
function M.country_block(ip, request_id)
	return clean_exit('country_block.html', { ip = ip, request_id = request_id }, 403, ngx.HTTP_FORBIDDEN)
end

-- Debug exit
function M.debug(message)
	return clean_exit(message, 200, ngx.OK)
end

return M