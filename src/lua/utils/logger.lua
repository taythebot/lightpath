local logger = require "resty.logger.socket"
local cjson = require "cjson"

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
local var_reason = ngx.var.reason or nil
local request_country = ngx.var.geoip2_data_country_code

local M = {}

-- Init logger client
function M.init(host, port, proto)
    if not logger.initted() then
        local ok, err = logger.init {
            host = host,
            port = port,
            sock_type = proto,
            flush_limit = 1,
            drop_limit = 5678,
        }

        if not ok then
            return nil, "Failed to initialize logger: " .. err
        end
    end

    return true, nil
end

-- Log nginx request
function M.log_request()
    local compression
    local reason
    local headers = ngx_req_get_headers()

    -- Determine compression used
    if ngx.header["Content-Encoding"] == "br" then
        compression = "brotli"
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
        http_referer = headers["referer"],
        user_agent = headers["user-agent"],
        cache_status = ngx.header["X-Cache-Status"] or "MISS",
        cache_ttl = ngx.header["X-Cache-TTL"],
        cache_key = ngx.header["X-Cache-Key"],
        server_id = ngx.header["X-Server-ID"],
        compression = compression,
        reason = var_reason,
        country = request_country
    })

    local bytes, err = logger.log(msg)

    if err then
        return nil, "Failed to log message: " .. err
    end

    return bytes, nil
end

return M