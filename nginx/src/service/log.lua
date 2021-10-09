--local cjson = require 'cjson'
--local raven = require 'sm.utils.raven'
--local raven_sender = require 'sm.utils.raven.senders.src-resty-http'
--local logger = require 'resty.logger.socket'

local server_id = os_getenv('SERVER_ID')
local request_id = ngx.var.request_id
local exception = ngx.ctx.exception
local reason = ngx.ctx.reason

local headers = ngx.req.get_headers()
local content_encoding = ngx.header['Content-Encoding']
local metadata_id

local log = ngx.log
local ERR = ngx.ERR

-- Handle exceptions
if exception then
	log(ERR, exception)

	-- Initiate Raven
	--local rvn = raven.new {
	--	sender = raven_sender.new {
    --  -- replace with your sentry endpoint
	--		dsn = 'http://6967b8d0aaf54e329b33d75080b3b1f5:31ad5b1e1839438d804ba8fea02a15a0@sentry:9000/3',
	--	},
	--	tags = {
	--		server = server_id,
	--		request = request
	--	}
	--}
	--
	---- Send exception to Sentry
	--local id, err = rvn:captureException(exception)
	--
	---- Record Sentry event ID in CDN logs
	--if id then
	--	metadata_id = id
	--else
	--	metadata_id = 'SENTRY_FAILURE'
	--
	--	-- Output failure to nginx logs
	--	log(ERR, '[Log] Failed to send error to Sentry: ', err)
	--end
end

-- Initiate socket logger
--if not logger.initted() then
--	local ok, err = logger.init{
--	    host = 'vector-openresty',
--	    port = 1337,
--	    flush_limit = 1234,
--	    drop_limit = 5678,
--	}
--	if not ok then
--	    return log(ERR, '[Log] Failed to initialize the logger: ', err)
--	end
--end

-- Construct message
--local msg = {
--	request_id = ngx.var.request_id,
--	zone_id = ngx.ctx.zone_id,
--	remote_addr = ngx.var.remote_addr,
--	request_date = ngx.time(),
--	request_method = ngx.req.get_method(),
--	request_time = ngx.var.request_time,
--	bytes = ngx.var.bytes_sent,
--	host = ngx.var.host,
--	request_uri = ngx.var.request_uri,
--	status = ngx.status,
--	http_referer = headers['referer'],
--	user_agent = headers['user-agent'],
--	cache_status = ngx.var.upstream_cache_status or 'MISS',
--	cache_ttl = cache_ttl,
--	cache_key = cache_key,
--	server_id = os.getenv('SERVER_ID'),
--	server_colo = os.getenv('SERVER_COLO'),
--	compression = content_encoding,
--	request_country = ngx.var.geoip2_data_country_code,
--	request_asn = ngx.var.geoip2_data_asn_number or 'AS12345',
--}
--
---- Set reason as metadata_id
--if reason then
--	metadata_id = reason
--end
--
---- Add metadata_id to message
--msg['metadata_id'] = message
--
---- Encode and send message
--local bytes, err = logger.log(cjson.encode(msg))
--
--if err then
--	return log(ERR, '[Log] Failed to send message: ', err)
--end
