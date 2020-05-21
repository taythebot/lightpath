local logger = require 'resty.logger.socket'
local cjson = require 'cjson'

local log = ngx.log
local ERR = ngx.ERR

local ngx_req_get_headers = ngx.req.get_headers
local request_id = ngx.var.request_id
local timestamp = ngx.var.time_iso8601
local remote_addr = ngx.var.remote_addr
local host = ngx.var.host
local request_uri = ngx.var.request_uri
local status = ngx.status
local bytes_sent = ngx.var.bytes_sent
local request_time = ngx.var.request_time
local method = ngx.req.get_method
local reason = ngx.ctx.reason
local request_country = ngx.var.geoip2_data_country_code
local request_asn = ngx.var.geoip2_data_asn_number


-- Init logger client
if not logger.initted() then
	local ok, err = logger.init{
		host = 'host.docker.internal',
		port = 514,
		sock_type = 'tcp',
		flush_limit = 1,
		drop_limit = 5678,
	}

	if not ok then
		log(ERR, 'Failed to initialize logger: ', err)
		return
	end
end

-- Log nginx request
local compression
local reason
local headers = ngx_req_get_headers()
local content_encoding = ngx.header['Content-Encoding']

-- Determine compression used
if content_encoding == 'br' then
	compression = 'brotli'
elseif content_encoding == 'gzip' then
	compression = 'gzip'
end

if ngx.status == 403 then
	reason = var_reason
end

local msg = cjson.encode({
	id = request_id,
	date = timestamp,
	ip = remote_addr,
	method = method(),
	host = host,
	uri = request_uri,
	status = status,
	bytes = bytes_sent,
	request_time = request_time,
	http_referer = headers['referer'],
	user_agent = headers['user-agent'],
	cache_status = ngx.header['X-Cache-Status'] or 'MISS',
	cache_ttl = ngx.header['X-Cache-TTL'],
	cache_key = ngx.header['X-Cache-Key'],
	server_id = ngx.header['X-Server-ID'],
	compression = compression,
	reason = reason,
	country = request_country
})

local bytes, err = logger.log(msg)

if err then
	log(ERR, 'Failed to log message: ', err)
	return
end