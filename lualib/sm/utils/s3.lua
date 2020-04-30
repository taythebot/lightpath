local hmac = require 'resty.hmac'
local sha256 = require 'resty.sha256'
local str = require 'resty.string'
local http = require 'resty.http'

local log = ngx.log
local ERR = ngx.ERR

local M = {}
local mt = { __index = M }

function M:new(access_key, secret_key, bucket, host, port, timeout)
	if not access_key or type(access_key) ~= 'string' then
		return nil, 'Access key required'
	end

	if not secret_key or type(secret_key) ~= 'string' then
		return nil, 'Secret key required'
	end

	if not bucket or type(bucket) ~= 'string' then
		return nil, 'Bucket name required'
	end

	if not host or type(host) ~= 'string' then
		return nil, 'S3 host required'
	end

	if not port or type(port) ~= 'number' then
		return nil, 'S3 port required'
	end

	if not timeout or type(timeout) ~= 'number' then
		timeout = 1000 
	end

	return setmetatable({ access_key=access_key, secret_key=secret_key, bucket=bucket, host=host, port=port, timeout=timeout }, mt)
end

local function get_iso8601_basic(timestamp)
	return os.date('!%Y%m%dT%H%M%SZ', timestamp)
end

local function get_iso8601_basic_short(timestamp)
	return os.date('!%Y%m%d', timestamp)
end

local function get_derived_signing_key(secret_key, timestamp, region, service)
	local h_date = hmac:new('AWS4' .. secret_key, hmac.ALGOS.SHA256)
	
	h_date:update(get_iso8601_basic_short(timestamp))
	
	local k_date = h_date:final()

	local h_region = hmac:new(k_date, hmac.ALGOS.SHA256)
	
	h_region:update(region)
	
	local k_region = h_region:final()

	local h_service = hmac:new(k_region, hmac.ALGOS.SHA256)
	
	h_service:update(service)
	
	local k_service = h_service:final()

	local h = hmac:new(k_service, hmac.ALGOS.SHA256)
	
	h:update('aws4_request')
	
	return h:final()
end

local function get_cred_scope(timestamp, region, service)
	return get_iso8601_basic_short(timestamp)
	.. '/' .. region
	.. '/' .. service
	.. '/aws4_request'
end

local function get_signed_headers(range)
	if range then
		return 'host;range;x-amz-content-sha256;x-amz-date'
	else
		return 'host;x-amz-content-sha256;x-amz-date'
	end
end

local function get_sha256_digest(s)
	local h = sha256:new()
	
	h:update(s or '')
	
	return str.to_hex(h:final())
end

local function get_hashed_canonical_request(timestamp, host, method, uri, request_body, range)
	local digest = get_sha256_digest(request_body)
	local headers

	-- Range header must be placed in specific line for signature
	if range then
		headers = 'host:' .. host .. '\n'
		.. 'range:' .. range .. '\n'
		.. 'x-amz-content-sha256:' .. digest .. '\n'
		.. 'x-amz-date:' .. get_iso8601_basic(timestamp) .. '\n'
	else
		headers = 'host:' .. host .. '\n'
		.. 'x-amz-content-sha256:' .. digest .. '\n'
		.. 'x-amz-date:' .. get_iso8601_basic(timestamp) .. '\n' 
	end

	local canonical_request = method .. '\n'
	.. uri .. '\n'
	.. '\n'
	.. headers
	.. '\n'
	.. get_signed_headers(range) .. '\n'
	.. digest

	return get_sha256_digest(canonical_request)
end

local function get_string_to_sign(timestamp, region, service, method, host, uri, request_body, range)
	return 'AWS4-HMAC-SHA256\n'
	.. get_iso8601_basic(timestamp) .. '\n'
	.. get_cred_scope(timestamp, region, service) .. '\n'
	.. get_hashed_canonical_request(timestamp, host, method, uri, request_body, range)
end

local function get_signature(derived_signing_key, string_to_sign)
	local h = hmac:new(derived_signing_key, hmac.ALGOS.SHA256)
	h:update(string_to_sign)
	return h:final(nil, true)
end

local function get_authorization(secret_key, access_key, timestamp, region, service, method, host, uri, request_body, range)
	local derived_signing_key = get_derived_signing_key(secret_key, timestamp, region, service)

	local string_to_sign = get_string_to_sign(timestamp, region, service, method, host, uri, request_body, range)

	local auth = 'AWS4-HMAC-SHA256 '
	.. 'Credential=' .. access_key .. '/' .. get_cred_scope(timestamp, region, service)
	.. ',SignedHeaders=' .. get_signed_headers(range)
	.. ',Signature=' .. get_signature(derived_signing_key, string_to_sign)

	return auth
end

local function authorization_v4(secret_key, access_key, method, host, uri, request_body, range)
	local headers = {}
	local timestamp = tonumber(ngx.time())
	local auth = get_authorization(secret_key, access_key, timestamp, 'us-east-1', 's3', method, host, uri, request_body, range)

	headers['Authorization'] = auth
	headers['Host'] = host
	headers['x-amz-date'] = get_iso8601_basic(timestamp)
	headers['x-amz-content-sha256'] = get_sha256_digest(request_body)

	if range then
		headers['Range'] = range
	end

	return headers
end

function M:get(key, range)
	-- Create URI
	local uri = '/' .. self.bucket .. '/' .. key

	-- Generate authorization v4 header
	local headers = authorization_v4(self.secret_key, self.access_key, 'GET', self.host, uri, nil, range)

	-- Start new HTTP instance
	local httpc = http.new()

	-- Set timeout
	httpc:set_timeout(self.timeout)

	-- Connect to Minio
	httpc:connect(self.host, self.port)

	-- Make request
	local res, err = httpc:request({
		version = 1.1,
		method = 'GET',
		path = uri,
		headers = headers,
	})

	if not res then
		return nil, nil, 'Failed to make request to S3: ' .. err
	end

	-- Return request and http instance
	return res, httpc, nil
end


return M