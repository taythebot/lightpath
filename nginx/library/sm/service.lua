local M = {}

function M.run(global_config)
	-- Load essential packages
	local logger = require('sm.utils.logger').load(global_config)
	local exit = require('sm.utils.exit').load(global_config)

	-- Prepare rate limit
	-- local rate_limit = require('sm.utils.rate_limit').load(global_config)
	-- local limit_key = ngx.var.limit_key
	
	-- -- Perform rate limit check
	-- local ok = rate_limit.check(limit_key)

	-- if not ok then
	-- 	-- Block request
	-- 	exit.rate_limit()
	-- end

	-- Fetch configuration
	local config_fetcher = require('sm.utils.config_fetcher')
	local config = config_fetcher.load(global_config)

	-- Load main packages
	local sticky = require('sm.utils.sticky').load(config)
	local challenge = require('sm.utils.challenge').load(config)

	-- Assign variables
	local uid = ngx.var.sm_uid
	local website = config['host']
	local ssl_level = config['ssl_level']
	local backend =  config['backend']
	local sticky_name = config['sticky_cookie'] or config['cookie']['sticky']
	local security_level = config['security_level'] or 'challenge'
	local challenge_name = config['challenge_name'] or config['cookie']['challenge']
	local challenge_pass = config['challenge_pass'] or config['cookie']['pass']
	local challenge_time = tonumber(config['grace_period']) or 1800

	-- Check for sticky session
	local sticky_session = sticky.check(sticky_name)

	if sticky_session then
		-- Verify sticky session
		local ok = sticky.verify(sticky_name, uid)

		if not ok then
			-- Malformed sticky session, possible reuse. Raise IP reputation
			sticky.remove(sticky_name, website)
		end
	else
		-- Set sticky session
		sticky.set(sticky_name, uid, website)
	end

	-- Security check
	if security_level ~= 'none' then
		-- Prepare security checks
		local check = challenge.check(website, challenge_name, challenge_time, challenge_pass, config['challenge'])

		-- Perform security checks
		if not check then
			-- Display challenge based on security level
			if security_level == 'challenge' then
				challenge.invoke_challenge(website, challenge_name, challenge_time, config['challenge'])
			elseif security_level == 'captcha' then
				local captcha_level = config['captcha_level']
				local m = ngx.re.match(ngx.var.request_uri, '^/sm-protect/verify(?!.*\\\\/)')
				-- Check request uri
				if m then
					-- Generate challenge
					challenge.verify_captcha_v2(captcha_level, website, challenge_time, challenge_pass, config['challenge'])
				else
					-- Generate and invoke browser challenge
					challenge.invoke_captcha_v2(captcha_level, config['challenge'])
				end
			end
		end
	end

	-- Check and execute rate limit
	-- if config['rate_limit'] == 'true' then
	-- 	rate_limit.execute(limit_key, tonumber(config['rate_limit_requests']), tonumber(config['rate_limit_window']), tonumber(config['rate_limit_cooldown']))
	-- end

	-- Redirect http to https
	if config['https'] == 'true' and ngx.var.scheme == 'http' then
		ngx.redirect('https://' .. website .. ngx.var.request_uri, 301)
	end

	-- Cache
	require('ledge').create_handler():run()


	-- Push final backend to Nginx variable
	ngx.var.backend = (ssl_level == 'strict' and 'https://' or 'http://') .. backend

	return _M
end

return M