local M = {}

function M.load(config)
	local _M = {}

	local logger = require('sm.utils.logger').load(config)
	local template = require('sm.utils.template')

	-- Exit Nginx with status and exit code
	local function clean_exit(html, status, code)
		ngx.header['content-type'] = 'text/html'
		ngx.status = status
		ngx.print(html)
		ngx.exit(code)
		return
	end

	-- Browser challenge
	function _M.browser_challenge(website, script)
		local html = template.render('challenge.html', { website = website, script = script })
		clean_exit(html, 503, ngx.OK)
		return
	end

	-- Captcha v2 challenge
	function _M.captcha_v2_challenge(mode, token)
		local html = template.render('captcha_v2_' .. mode .. '.html', { ip = ngx.var.remote_addr, request_id = ngx.var.sm_request_id, token = token, site_key = config['captcha'][mode .. '_site_key'] })
		clean_exit(html, 403, ngx.OK)
		return
	end

	-- Configuration missing
	function _M.config()
		local html = template.render('config.html', { ip = ngx.var.remote_addr, request_id = ngx.var.sm_request_id })
		clean_exit(html, 520, ngx.OK)
		return
	end

	-- Internal SM error
	function _M.error(message)
		if message then
			logger.error(message)
		end

		local html = template.render('520.html', { ip = ngx.var.remote_addr, request_id = ngx.var.sm_request_id })
		clean_exit(html, 520, ngx.OK)
		return
	end

	-- Rate limit block
	function _M.rate_limit()
		local html = template.render('429.html', { ip = ngx.var.remote_addr, request_id = ngx.var.sm_request_id })
		clean_exit(html, 429, ngx.OK)
		return
	end

	-- Debug exit
	function _M.debug(message)
		clean_exit(message, 200, ngx.OK)
		return
	end

	return _M
end

return M