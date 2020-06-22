-- Load essential libraries
local config = require 'sm.config'
local cache = require 'sm.purge.utils.cache'
local vault = require 'sm.purge.utils.vault'
local cjson = require 'cjson'
local jwt = require 'resty.jwt'
local validators = require 'resty.jwt-validators'

-- Variables
local log = ngx.log
local ERR = ngx.ERR
local OK = ngx.OK
local ngx_http_close = ngx.HTTP_CLOSE
local ngx_http_ok = ngx.HTTP_OK
local ngx_http_error = ngx.HTTP_INTERNAL_SERVER_ERROR
local ngx_http_forbidden = ngx.HTTP_FORBIDDEN
local ngx_bad_request = ngx.HTTP_BAD_REQUEST
local ngx_say = ngx.say
local ngx_exit = ngx.exit
local ngx_req_get_headers = ngx.req.get_headers
local ngx_req_get_method = ngx.req.get_method
local string_lower = string.lower
local server_id = string_lower(os.getenv('SERVER_ID'))

-- Check for headers
local headers = ngx.req.get_headers()

if headers['X-Purge-Request'] ~= 'true' or not headers['Authorization'] or not headers['X-Key-Signature'] then
	ngx_exit(ngx_http_close)
end

-- Get JWT secret from cache
local secret, signature, cache_status, err = cache.get('auth', vault.get, 'edge/data/' .. server_id .. '/auth', 'secret')

if err then
	log(ERR, 'Error occurred while fetching secret from cache: ', err)
	ngx_exit(ngx_http_error)
end

if cache_status ~= 'HIT' and cache_status ~= nil then
	log(OK, 'Internal cache status: ', cache_status)
end

-- Compare key signature
if signature ~= headers['X-Key-Signature'] then
	log(ERR, 'Key signature mismatch. Updating key...')

	secret, signature, cache_status, err = cache.update('auth', vault.get, 'edge/data/' .. server_id .. '/auth', 'secret')
	
	if err then
		log(ERR, 'Error occurred while updating secret: ', err)
		ngx_exit(ngx_http_error)
	end

	log(OK, 'key signature is ', signature)

	-- Check signature again
	if signature ~= headers['X-Key-Signature'] then
		log(ERR, 'Key signature still mismatched after update. Closing connection')
		ngx_exit(ngx_http_close)
	end
end

-- Verify JWT
local jwt_verify = jwt:verify(secret, headers['Authorization'], {
	aud = function(val)
		return val == server_id
	end,
	iss = function(val)
		return val == 'Light Path CDN'
	end,
	exp = validators.opt_is_not_expired()
})

if not jwt_verify.verified then
	log(ERR, 'JWT verification failed: ', jwt_verify.reason)
	ngx_exit(ngx_http_close)
end

-- Check method
if ngx_req_get_method() ~= 'PURGE' then
	ngx.header['Content-Type'] = 'application/json; charset=utf-8'
	ngx_say(cjson.encode({ success = false, message = 'Method not supported'}))
	ngx_exit(ngx_bad_request)
end