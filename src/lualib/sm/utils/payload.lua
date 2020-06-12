local M = {}

function M.load(config)
	local _M = {}

	local exit = require('sm.utils.exit').load(config)
	local cookie = require('sm.utils.cookie').load(config)
	local aes_handler = require('resty.aes')
	local str = require('resty.string')
	local hmac = require('resty.hmac')
	local sha1_handler = require('resty.sha1')
	local ngx_re = require('ngx.re')
	local http = require('resty.http')
	local cjson = require('cjson')

	-- Initiate aes instance
	local function aes_init(key, salt)
		local aes = aes_handler:new(key, salt, aes_handler.cipher(256, 'cbc'), aes_handler.hash.sha512, 5)

		if not aes then
			exit.error('Payload Error: [AES][INIT] Failed to initialize aes instance')
		end

		return aes
	end

	-- Initiate hmac instance
	local function hmac_init(algo, secret)
		local hmac = hmac.new(algo, secret)

		if not hmac then 
			exit.error('Payload Error: [HMAC][INIT] Failed to initialize hmac instance')
		end

		return hmac
	end

	-- Initiate sha1 instance
	local function sha1_init()
		if not _M.sha1 then
			local sha1 = sha1_handler:new()

			if not sha1 then
				exit.error('Payload Error: [SHA1][INIT] Failed to initialize md5 instance')
			end

			_M.sha1 = sha1
		end

		return
	end

	-- Convert hex to ascii for aes decryption
	local function hex_to_ascii(hex)
		local c_table = {};

		for jj = 0, 255 do
			c_table[("%02X"):format(jj)] = string.char(jj);
			c_table[("%02x"):format(jj)] = string.char(jj);
		end

		return hex:gsub("(..)", c_table);
	end

	-- Generate sticky session value
	function _M.generate_uid()
		local sha1 = sha1_init()

		-- Update sha1 object
		local ok = _M.sha1:update(string.format('%s,%s,%s', ngx.var.remote_addr, ngx.var.http_user_agent, config['server']['hash']))

		if not ok then
			exit.error('Payload Error: [SHA1] Failed to update sha1 object')
		end

		-- Generate sha1 hash
		local final = _M.sha1:final()

		if not final then
			exit.error('Payload Error: [SHA1] Failed to finalize sha1 object')
		end

		return str.to_hex(final)
	end

	-- Generate challenge 
	function _M.generate_challenge(aes_key, aes_salt, hmac_secret)
		local aes = aes_init(aes_key, aes_salt)
		local hmac = hmac_init('sha1', hmac_secret)

		-- Generate random delays
		local delay_min = math.random(5, 7)
		local delay_max = delay_min + math.random(1, 3)	

		-- Generate timestamps
		local timestamp_start = ngx.time()
		local timestamp_min = timestamp_start + delay_min
		local timestamp_max = timestamp_start + delay_max

		-- Generate payload (NO NEED TO CHECK STICKY SESSION, IT IS ALREADY CHECKED BEFORE HAND, IF WRONG IT IS SET AND CUSTOMER RELOADED)
		local pre = string.format('%s,%s,%s', ngx.var.sm_uid, timestamp_min, timestamp_max)

		-- Update hmac object
		local ok = hmac:update(pre)

		if not ok then
			exit.error('Payload Error: [HMAC] Failed to update hmac object')
		end

		-- Generate hmac signature
		local mac = hmac:final()

		if not mac then
			exit.error('Payload Error: [HMAC] Failed to finalize hmac object')
		end

		-- Encrypt using aes
		local payload = aes:encrypt(pre .. '+' .. mac)

		return delay_min, delay_max, timestamp_max, str.to_hex(payload)
	end

	-- Verify challenge
	function _M.verify_challenge(challenge, aes_key, aes_salt, hmac_secret)
		local aes = aes_init(aes_key, aes_salt)
		local hmac = hmac_init('sha1', hmac_secret)

		-- Attempt to decrypt challenge after converting hex to ascii
		local payload = aes:decrypt(hex_to_ascii(challenge))

		if not payload then
			-- Encryption failed
			return false
		end

		-- Split payload by +
		local res, err = ngx_re.split(payload, '\\+')

		if not res then
			exit.error('Payload Error: ' .. err)
		end

		-- Update hmac object
		local ok = hmac:update(res[1])

		if not ok then
			exit.error('Payload Error: [HMAC] Failed to update hmac object')
		end

		-- Generate hmac signature
		local mac = hmac:final()

		if not mac then
			exit.error('Payload Error: [HMAC] Failed to finalize hmac object')
		end

		-- Compare signatures
		if res[2] ~= mac then
			-- Signature mismatch
			return false
		end

		-- Split payload by comma
		local res, err = ngx_re.split(res[1], ',')

		if not res then
			exit.error('Payload Error: ' .. err)
		end

		-- Compare uid
		if res[1] ~= ngx.var.sm_uid then
			-- UID mismatch
			return false
		end

		local now = ngx.time()

		-- Check expiration
		if tonumber(res[2]) > now and tonumber(res[3]) < now then
			-- Expired
			return false
		end

		-- Fallback response
		return true
	end

	-- Generate pass
	function _M.generate_pass(website, challenge_time)
		local sha1 = sha1_init()

		-- Generate timestamps
		local pass_start = ngx.time()
		local pass_end = pass_start + challenge_time

		-- Update sha1 object
		local ok = _M.sha1:update(string.format('%s,%s,%s,%s,%s', ngx.var.remote_addr, ngx.var.http_user_agent, config['server']['hash'], website, pass_end))

		if not ok then
			exit.error('Payload Error: [SHA1] Failed to update sha1 object')
		end

		-- Generate sha1 hash for uid
		local final = _M.sha1:final()

		if not final then
			exit.error('Payload Error: [SHA1] Failed to finalize sha1 object')
		end

		-- Convert sha1 ascii to hex
		local uid = str.to_hex(final)

		-- Concatenate variables into pass
		local pass = uid .. '-' .. pass_end

		return pass
	end

	-- Verify pass
	function _M.verify_pass(website, pass)
		local sha1 = sha1_init()

		-- Split payload by comma
		local res, err = ngx_re.split(pass, '\\-')

		if not res then
			exit.error('Payload Error: ' .. err)
		end

		-- Update sha1 object
		local ok = _M.sha1:update(string.format('%s,%s,%s,%s,%s', ngx.var.remote_addr, ngx.var.http_user_agent, config['server']['hash'], website, res[2]))

		if not ok then
			exit.error('Payload Error: [SHA1] Failed to update sha1 object')
		end

		-- Generate sha1 hash for uid
		local final = _M.sha1:final()

		if not final then
			exit.error('Payload Error: [SHA1] Failed to finalize sha1 object')
		end

		-- Convert sha1 ascii to hex
		local uid = str.to_hex(final)

		-- Verify uid
		if res[1] ~= uid then
			-- Uid mistmatch
			return false
		end

		-- Check expiration
		if tonumber(res[2]) < ngx.time() then
			-- Expired
			return false
		end

		-- Fallback response
		return true
	end

	-- Generate captcha v2 token
	function _M.generate_captcha_token(aes_key, aes_salt, hmac_secret)
		local aes = aes_init(aes_key, aes_salt)
		local hmac = hmac_init('sha1', hmac_secret)

		-- Generate timestamps
		local timestamp_start = ngx.time()
		local timestamp_max = timestamp_start + 180

		-- Generate payload (NO NEED TO CHECK STICKY SESSION, IT IS ALREADY CHECKED BEFORE HAND, IF WRONG IT IS SET AND CUSTOMER RELOADED)
		local pre = string.format('%s,%s,%s,%s', ngx.var.sm_uid, timestamp_start, timestamp_max, ngx.var.request_uri)

		-- Update hmac object
		local ok = hmac:update(pre)

		if not ok then
			exit.error('Payload Error: [HMAC] Failed to update hmac object')
		end

		-- Generate hmac signature
		local mac = hmac:final()

		if not mac then
			exit.error('Payload Error: [HMAC] Failed to finalize hmac object')
		end

		-- Encrypt using aes
		local payload = aes:encrypt(pre .. '+' .. mac)

		return str.to_hex(payload)
	end

	-- Verify captcha v2 token
	function _M.verify_captcha_token(captcha_level, aes_key, aes_salt, hmac_secret)
		-- Check if parameters are there
		local param = ngx.req.get_query_args()

		if not param['token'] or not param['g-recaptcha-response'] then
			-- Missing parameters
			return false
		end

		-- Initiate crypto instaces
		local aes = aes_init(aes_key, aes_salt)
		local hmac = hmac_init('sha1', hmac_secret)

		-- Attempt to decrypt challenge after converting hex to ascii
		local payload = aes:decrypt(hex_to_ascii(param['token']))

		if not payload then
			-- Encryption failed
			return false
		end

		-- Split payload by +
		local res, err = ngx_re.split(payload, '\\+')

		if not res then
			exit.error('Payload Error: ' .. err)
		end

		-- Update hmac object
		local ok = hmac:update(res[1])

		if not ok then
			exit.error('Payload Error: [HMAC] Failed to update hmac object')
		end

		-- Generate hmac signature
		local mac = hmac:final()

		if not mac then
			exit.error('Payload Error: [HMAC] Failed to finalize hmac object')
		end

		-- Compare signatures
		if res[2] ~= mac then
			-- Signature mismatch
			return false
		end

		-- Split payload by comma
		local res, err = ngx_re.split(res[1], ',')

		if not res then
			exit.error('Payload Error: ' .. err)
		end

		-- Compare uid
		if res[1] ~= ngx.var.sm_uid then
			-- UID mismatch
			return false
		end

		local now = ngx.time()

		-- Check expiration
		if (tonumber(res[2]) + 1) > now or tonumber(res[3]) < now or not res[4] then
			-- Expired
			return false
		end

		-- Verify captcha
		local payload = 'secret=' .. config['captcha'][captcha_level .. '_secret_key'] .. '&response=' .. param['g-recaptcha-response'] .. '&remoteip=' .. ngx.var.remote_addr

		-- Initiate http
		local httpc = http.new()

		-- Make request
		local response, err = httpc:request_uri('https://www.google.com/recaptcha/api/siteverify', {
			method = 'post',
			headers = {
				['Content-Type'] = 'application/x-www-form-urlencoded',
			},
			body = payload
		})

		if not response then
			exit.error('Payload Error: [Captcha] ' .. err)
		end

		-- Decode response body
		local body = cjson.decode(response.body)

		-- Check response
		if body['success'] == false then
			return false
		end

		-- Fallback response
		return true, res[4]
	end

	return _M
end

return M