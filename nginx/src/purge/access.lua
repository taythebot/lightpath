-- Load essential libraries
local config = require "lightpath.config"
local cache = require "lightpath.utils.internal_cache"
local helpers = require "lightpath.purge.utils.helpers"
local cjson = require "cjson"
local jwt = require "resty.jwt"
local validators = require "resty.jwt-validators"

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
local os_getenv = os.getenv
local server_id = string_lower(os_getenv("SERVER_ID"))

-- Check for headers
local headers = ngx.req.get_headers()
if headers["X-Purge-Request"] ~= "true" or not headers["Authorization"] or not headers["X-Key-Signature"] then
    return ngx_exit(ngx_http_close)
end

-- Initiate internal cache_
local cache, err = cache.new(config["internal"])
if err then
    log(ERR, "Error occurred while initializing cache: ", err)
    return ngx_exit(ngx_http_error)
end

-- Get JWT secret from cache
local value, cache_status, err = cache:get("auth", helpers.get_auth, "edge/data/" .. server_id .. "/auth", "secret", server_id)
if err then
    log(ERR, "Error occurred while fetching secret from cache: ", err)
    return ngx_exit(ngx_http_error)
end

if cache_status ~= "HIT" and cache_status ~= nil then
    log(OK, "Internal cache status: ", cache_status)
end

-- Parse secret and signature
local secret, signature = helpers.parse(value)
if not secret or not signature then
    log(ERR, "Failed to parse cache value")
    return ngx_exit(ngx_http_error)
end

-- Compare key signature
if signature ~= headers["X-Key-Signature"] then
    value, cache_status, err = cache.update("auth", helpers.get_auth, "edge/data/" .. server_id .. "/auth", "secret", server_id)
    if err then
        log(ERR, "Error occurred while updating secret: ", err)
        return ngx_exit(ngx_http_error)
    end

    -- Parse secret and signature
    secret, signature = helpers.parse(value)
    if not secret or not signature then
        log(ERR, "Failed to parse cache value")
        return ngx_exit(ngx_http_error)
    end

    -- Check signature again
    if signature ~= headers["X-Key-Signature"] then
        log(ERR, "Key signature still mismatched after update. Closing connection")
        return ngx_exit(ngx_http_forbidden)
    end
end

-- Verify JWT
local jwt_verify = jwt:verify(secret, headers["Authorization"], {
    aud = function(val)
        return val == server_id
    end,
    iss = function(val)
        return val == "Light Path CDN"
    end,
    exp = validators.opt_is_not_expired()
})

if not jwt_verify.verified then
    log(ERR, "JWT verification failed: ", jwt_verify.reason)
    return ngx_exit(ngx_http_forbidden)
end

-- Check method
if ngx_req_get_method() ~= "PURGE" then
    ngx.header["Content-Type"] = "application/json; charset=utf-8"
    ngx_say(cjson.encode({ success = false, message = "Method not supported" }))
    return ngx_exit(ngx_bad_request)
end

-- Check for payloads
if not jwt_verify.payload.urls then
    ngx.header["Content-Type"] = "application/json; charset=utf-8"
    ngx_say(cjson.encode({ success = false, message = "Urls missing from payload" }))
    return ngx_exit(ngx_bad_request)
elseif not jwt_verify.payload.zone then
    ngx.header["Content-Type"] = "application/json; charset=utf-8"
    ngx_say(cjson.encode({ success = false, message = "Zone key missing from payload" }))
    return ngx_exit(ngx_bad_request)
end

ngx.ctx.urls = jwt_verify.payload.urls
ngx.ctx.key = jwt_verify.payload.zone