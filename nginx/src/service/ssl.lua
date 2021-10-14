local ssl = require "ngx.ssl"

local config = require "lightpath.config"
local redis = require "lightpath.utils.redis"
local config_fetcher = require "lightpath.utils.config_fetcher"
local ssl_cache = require "lightpath.utils.ssl_cache"

-- Variables
local ssl_server_name = ssl.server_name
local ssl_clear_certs = ssl.clear_certs
local ssl_cert_pem_to_der = ssl.cert_pem_to_der
local ssl_set_der_cert = ssl.set_der_cert
local ssl_priv_key_pem_to_der = ssl.priv_key_pem_to_der
local ssl_set_der_priv_key = ssl.set_der_priv_key
local ngx_re_match = ngx.re.match
local log = ngx.log
local ngx_exit = ngx.exit
local ERROR = ngx.ERROR
local ERR = ngx.ERR
local string_lower = string.lower
local os_getenv = os.getenv
local server_id = string_lower(os_getenv("SERVER_ID"))

-- Get TLS SNI
local server_name, err = ssl_server_name()
if not server_name then
    -- Fallback to default cert
    return log(ERR, "[SSL] Failed to get server name:", err)
end

-- Regex to see if sever name is subdomain of default domain
local match = ngx_re_match(server_name, "^(.*[a-zA-Z0-9].*\\.lightpath-cdn\\.net)$")
if match then
    -- Use default cert
    return
end

-- Connect to Redis
local ok, err = redis.connect(config["redis"])
if not ok then
    -- Fallback to default cert, error will be handled in access
    return log(ERR, "[SSL] Failed to connect to Redis: ", err)
end

-- Get hostname config
local hostname, hit_level, err = config_fetcher.hostname(redis, server_name)
if not hostname or not hostname["ambassador"] then
    -- Always close Redis and fallback to default cert, error will be handled in access
    return redis.close()
end

-- Initiate ssl cache
local cache, err = ssl_cache.new(config["ssl"], config["internal"], config["ambassador"])
if not cache then
    -- Fallback to default cert
    redis.close()
    return log(ERR, "[SSL] Failed to initialize SSL cache: ", err)
end

-- Lookup certificate in cache or fetch from Ambassador
local certificate, private_key, cache_status, err = cache:get(server_name, server_id, hostname.ambassador)
if err then
    -- Fallback to default cert
    redis.close()
    return log(ERR, "[SSL] ", err)
end

-- Clear default ssl cert and key at the very end to ensure fallback to default ssl certs work
local ok, err = ssl_clear_certs()
if not ok then
    redis.close()
    log(ERR, "[SSL] Failed to clear default certificate: ", err)
    return ngx_exit(ERROR)
end

-- Convert certificate to DER
local der_cert_chain, err = ssl_cert_pem_to_der(certificate)
if not der_cert_chain then
    -- Log and exit with error, no fallback here
    redis.close()
    log(ERR, "Failed to convert certificate chain from PEM to DER: ", err)
    return ngx_exit(ERROR)
end

-- Set DER certificate
local ok, err = ssl_set_der_cert(der_cert_chain)
if not ok then
    -- Log and exit with error, no fallback here
    redis.close()
    log(ERR, "Failed to set DER cert: ", err)
    return ngx_exit(ERROR)
end

-- Convert private key to DER
local der_pkey, err = ssl_priv_key_pem_to_der(private_key)
if not der_pkey then
    -- Log and exit with error, no fallback here
    redis.close()
    log(ERR, "Failed to convert certificate chain from PEM to DER: ", err)
    return ngx_exit(ERROR)
end

-- Set DER private key
local ok, err = ssl_set_der_priv_key(der_pkey)
if not ok then
    -- Log and exit with error, no fallback here
    redis.close()
    log(ERR, "Failed to set DER private key: ", err)
    return ngx.exit(ngx.ERROR)
end