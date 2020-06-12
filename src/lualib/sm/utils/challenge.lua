local M = {}

function M.load(config)
	local _M = {}

	local exit = require('sm.utils.exit').load(config)
	local cookie = require('sm.utils.cookie').load(config)
	local template = require('sm.utils.template')
	local payload = require('sm.utils.payload').load(config)

	-- Create pass
	function _M.create_pass(website, challenge_time, challenge_pass)
		-- Generate pass
		local pass = payload.generate_pass(website, challenge_time)

		-- Set pass cookie
		cookie.set({
			key = challenge_pass,
			value = pass,
			path = '/',
			domain = '.' .. website,
			secure = false,
			httponly = true,
			expires = ngx.cookie_time(ngx.time() + challenge_time),
			samesite = 'strict'
		})

		return
	end

	-- Remove pass
	function _M.remove_pass(website, challenge_pass)
		-- Unset pass cookie
		cookie.set({
			key = challenge_pass,
			value = 'expired',
			domain = '.' .. website,
			expires = 'Thu, Jan 01 1970 00:00:00 UTC'
		})
	end

	-- Check for challenge pass
	function _M.check(website, challenge_name, challenge_time, challenge_pass, secrets)
		local pass = cookie.get(challenge_pass)
		local challenge = cookie.get(challenge_name)

		-- Check for pass and challenge cookies
		if not pass and challenge then
			-- No pass found but challenge found
			local verify = payload.verify_challenge(challenge, secrets['aes_key'], secrets['aes_salt'], secrets['hmac_secret'])

			-- Unset chllange cookie
			cookie.set({
				key = challenge_name,
				value = 'expired',
				domain = '.' .. website,
				expires = 'Thu, Jan 01 1970 00:00:00 UTC'
			})

			-- Check if pass is valid
			if not verify then
				return false
			end

			-- Generate pass
			_M.create_pass(website, challenge_time, challenge_pass)
			
		elseif pass and not challenge then
			-- Pass found, verify pass
			local verify = payload.verify_pass(website, pass)

			-- Check if pass is valid
			if not verify then
				_M.remove_pass(website, challenge_pass)
				return false
			end
		else
			return false
		end

		-- Fallback response
		return true
	end

	-- Invoke challenge
	function _M.invoke_challenge(website, challenge_name, challenge_time, secrets)
		-- Generate challenge
		local delay_min, delay_max, timestamp_max, px = payload.generate_challenge(secrets['aes_key'], secrets['aes_salt'], secrets['hmac_secret'])

		-- Compile template
		local script = template.render('/scripts/challenge.js', { challenge_name = challenge_name, delay_min = delay_min, delay_max = delay_max })

		-- Set cookie
		cookie.set({
			key = challenge_name,
			value = px,
			path = '/',
			domain = '.' .. website,
			secure = false,
			httponly = true,
			expires = ngx.cookie_time(timestamp_max),
			samesite = 'strict'
		})

		-- Output html and exit nginx
		exit.browser_challenge(website, script)

		return
	end

	-- Invoke captcha
	function _M.invoke_captcha_v2(mode, secrets)
		-- Generate challenge
		local px = payload.generate_captcha_token(secrets['aes_key'], secrets['aes_salt'], secrets['hmac_secret'])

		-- Output html and exit nginx
		exit.captcha_v2_challenge(mode, px)

		return
	end

	-- Verify captcha
	function _M.verify_captcha_v2(captcha_level, website, challenge_time, challenge_pass, secrets)
		-- Verify challenge
		local verify, url = payload.verify_captcha_token(captcha_level, secrets['aes_key'], secrets['aes_salt'], secrets['hmac_secret'])

		if not verify then
			ngx.redirect(ngx.var.scheme .. website, 302)
		end

		-- Generate pass
		_M.create_pass(website, challenge_time, challenge_pass)

		--  Redirect user
		ngx.redirect((config['https'] == 'true' and 'https://' or 'http://') .. website .. url, 301)

		return
	end

	-- Generate challenge script
	-- function _M.script(challenge_name)
	-- 	-- Generate random number for delays
	-- 	local delay_min = math.random(1000, 3000)
	-- 	local delay_range = math.random(1000, 5000)

	-- 	-- Compile template
	-- 	local html = template.render('/scripts/challenge.js', { challenge_name = challenge_name, delay_min = delay_min, delay_range = delay_range })

	-- 	-- Output html and exit nginx
	-- 	ngx.header['content-type'] = 'text/javascript'
	-- 	ngx.header['x-frame-options'] = 'SAMEORIGIN'
	-- 	ngx.status = 302
	-- 	ngx.print(html)
	-- 	ngx.exit(ngx.OK)

	-- 	return
	-- end

	-- [ALTERNATIVE] Generate actual challenge
	-- function _M.generate_alternative(challenge_name, sticky_name)
	-- 	local px = payload.generate_challenge(sticky_name)


	-- 	-- Invoke browser challenge
	-- 	exit.browser_challenge(website)
	-- end

	return _M
end

return M