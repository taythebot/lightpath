local logger = require 'resty.logger.socket'
local cjson = require 'cjson'

local log = ngx.log
local ERR = ngx.ERR

-- Init logger client
if not logger.initted() then
	local ok, err = logger.init{
		host = 'host.docker.internal',
		port = 514,
		sock_type = 'tcp',
		flush_limit = 4096,
		drop_limit = 1048576,
	}

	if not ok then
		log(ERR, 'Failed to initialize logger: ', err)
		return
	end
end

-- Log nginx request
local compression
local rule_id
local headers = ngx.req.get_headers()
local content_encoding = ngx.header['Content-Encoding']

-- Determine compression used
if content_encoding == 'br' then
	compression = 'brotli'
elseif content_encoding == 'gzip' then
	compression = 'gzip'
end

if ngx.status == 403 then
	rule_id = ngx.ctx.reason
end

local msg = cjson.encode({
	request_id = ngx.var.request_id,
	zone_id = ngx.ctx.zone_id,
	remote_addr = ngx.var.remote_addr,
	request_date = ngx.time(),
	request_method = ngx.req.get_method(),
	request_time = ngx.var.request_time,
	bytes = ngx.var.bytes_sent,
	host = ngx.var.host,
	request_uri = ngx.var.request_uri,
	status = ngx.status,
	http_referer = headers['referer'],
	user_agent = headers['user-agent'],
	cache_status = ngx.var.upstream_cache_status or 'MISS',
	cache_ttl = cache_ttl,
	cache_key = cache_key,
	server_id = ngx.var.server_id,
	server_colo = ngx.var.server_colo,
	compression = compression,
	request_country = ngx.var.geoip2_data_country_code,
	request_asn = ngx.var.geoip2_data_asn_number or 'AS12345',
	rule_id = rule_id
})

local bytes, err = logger.log(msg)

if err then
	log(ERR, 'Failed to log message: ', err)
	return
end