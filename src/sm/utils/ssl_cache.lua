-- Load essential libraries
local resty_lock = require "resty.lock"
local internal_cache = require "sm.utils.internal_cache"
local vault = require "sm.utils.vault"
local ambassador = require "sm.utils.ambassador"

-- Variables
local log = ngx.log
local ERR = ngx.ERR
local shared = ngx.shared
local setmetatable = setmetatable
local ngx_re_match = ngx.re.match
local token_expired = false
local retries = 3

local M = {}
local mt = { __index = M }

-- Parse certificate and private key from cache value using regex
local function parse_value(val)
    local matches = ngx_re_match(val, "^(?:(?!-{3,}(?:BEGIN|END) CERTIFICATE)[\\s\\S])*(-{3,}BEGIN CERTIFICATE(?:(?!-{3,}END CERTIFICATE)[\\s\\S])*?-{3,}END CERTIFICATE-{3,})(?![\\s\\S]*?-{3,}BEGIN CERTIFICATE[\\s\\S]+?-{3,}END CERTIFICATE[\\s\\S]*?$)(?:\\+)(-----BEGIN PRIVATE KEY-----[\\S\\s]*-----END PRIVATE KEY-----)|(^\\+-----BEGIN RSA PRIVATE KEY-----[\\S\\s]*-----END RSA PRIVATE KEY-----)/i")

    if not matches[1] then
        return nil, nil, "Certificate missing from value"
    elseif not matches[2] then
        return nil, nil, "Private key missing from value"
    end

    return matches[1], matches[2], nil
end

-- Initiate cache config
function M.new(ssl_config, internal_config, ambassador_config)
    -- Sanity checks
    local dict = shared[ssl_config["cache_dict"]]
    if not dict then
        return nil, "Shared dictionary "
        " .. ssl_config["
        cache_dict "] .. " " not found"
    end

    local lock = shared[ssl_config["lock_dict"]]
    if not lock then
        return nil, "Shared dictionary "
        " .. ssl_config["
        lock_dict "] .. " " not found"
    end

    if type(ssl_config["expiration"]) ~= "number" then
        return nil, "Expiration must be a number"
    end

    -- Initiate internal cache
    local internalc, err = internal_cache.new(internal_config)
    if err then
        return nil, "Error occurred while initializing internal cache: " .. err
    end

    -- Initate Ambassador
    local ambassadorc, err = ambassador.new(ambassador_config)
    if not ambassadorc then
        -- Fallback to default cert
        return nil, "Failed to initialize Lemur instance: " .. err
    end

    local self = {
        cache = dict,
        lock = ssl_config["lock_dict"],
        expiration = ssl_config["expiration"],
        internal_cache = internalc,
        ambassador = ambassadorc
    }

    return setmetatable(self, mt)
end

-- Unlock and return values
local function unlock_and_ret(lock, certificate, private_key, cache_status, err)
    local ok, lerr = lock:unlock()

    if not ok and lerr ~= "unlocked" then
        return nil, nil, nil, "Failed to unlock callback: " .. lerr
    end

    return certificate, private_key, cache_status, err
end

local function lock(lock, cache, key)
    -- Create new lock
    local lock, err = resty_lock:new(lock)

    if not lock then
        return nil, "Failed to create lock: " .. err
    end

    local elapsed, lerr = lock:lock(key)

    if not elapsed and lerr ~= "timeout" then
        return nil, "Failed to acquire lock: " .. lerr
    end

    -- Check if another worker has populated cache
    local val, err = cache:get(key)

    if err then
        return unlock_and_ret(lock, nil, nil, nil, err)
    elseif val then
        -- Parse value
        local certificate, private_key, err = parse_value(val)
        if err then
            -- Failed to parse value, will fetch new value from Ambassador
            return lock, nil
        end

        return unlock_and_ret(lock, certificate, private_key, "HIT", nil)
    end

    return lock, nil
end

-- Get secret from cache or fetch from ambassador
function M:get(key, server_id, ambassador_id)
    -- Key sanity check
    if type(key) ~= "string" then
        return nil, nil, nil, "Key must be a string"
    end

    if type(ambassador_id) ~= "string" then
        return nil, nil, nil, "Ambassador id must be a string"
    end

    -- Look up key in cache
    local val, err = self.cache:get(key)
    if val then
        ngx.log(ngx.OK, "certificate found in cache")

        -- Parse value
        local certificate, private_key, err = parse_value(val)

        if not err then
            -- If failed to parse value we will get new value from Ambassador
            return certificate, private_key, "HIT", nil
        end
    end

    -- Create new lock
    local lock, err = lock(self.lock, self.cache, key)
    if not lock then
        return nil, nil, nil, err
    end

    -- Reset token expired variable
    token_expired = false
    ngx.log(ngx.OK, "certificate not in cache")

    for i = 1, retries do
        local auth_token, cache_status, err

        -- Get Ambassador token
        if token_expired == true then
            -- If token is expired we force update
            auth_token, cache_status, err = self.internal_cache:update("ambassador", vault.get, "edge/data/" .. server_id .. "/ambassador", "token")
        else
            auth_token, cache_status, err = self.internal_cache:get("ambassador", vault.get, "edge/data/" .. server_id .. "/ambassador", "token")
        end

        if err then
            -- Log error, but do not fallback
            log(ERR, "[SSL] [", i, "/", retries, "] Error occurred while fetching Ambassador auth token from cache: ", err)
            goto continue
        end

        -- Get certificate from Ambassador
        val, token_expired, err = self.ambassador:get_certificate(auth_token, ambassador_id)
        if err then
            -- Log error, but do not fallback
            log(ERR, "[SSL] [", i, "/", retries, "] Failed to get certificate from Ambassador: ", err)
            goto continue
        end

        -- Certificate acquired break out
        if val then
            break
        end

        :: continue ::
    end

    -- Return if no certificate
    if not val then
        return nil, nil, nil, "Failed to acquire cerificate. " .. retries .. " attempts failed!"
    end

    -- Parse value
    local certificate, private_key = val["body"], val["private_key"]

    -- Save certificate and private key in cache
    local ok, err = self.cache:set(key, certificate .. "+" .. private_key, self.expiration)
    if err then
        return unlock_and_ret(lock, nil, nil, nil, err)
    end

    -- Return new value
    return unlock_and_ret(lock, certificate, private_key, "EXPIRED", nil)
end

return M