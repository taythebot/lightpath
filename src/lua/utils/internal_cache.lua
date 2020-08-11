local resty_lock = require "resty.lock"

local shared = ngx.shared
local setmetatable = setmetatable
local xpcall = xpcall
local traceback = debug.traceback
local tostring = tostring

local M = {}
local mt = { __index = M }

-- Initiate cache config
function M.new(config)
    -- Sanity checks
    local dict = shared[config["cache_dict"]]

    if not dict then
        return nil, "Shared dictionary " .. config["cache_dict"] .. " not found"
    end

    local lock = shared[config["lock_dict"]]

    if not lock then
        return nil, "Shared dictionary " .. config["lock_dict"] .. " not found"
    end

    if type(config["expiration"]) ~= "number" then
        return nil, "Expiration must be a number"
    end

    local self = {
        cache = dict,
        lock = config["lock_dict"],
        expiration = config["expiration"]
    }

    return setmetatable(self, mt)
end

-- Unlock and return values
local function unlock_and_ret(lock, val, cache_status, err)
    local ok, lerr = lock:unlock()

    if not ok and lerr ~= "unlocked" then
        return nil, nil, "Failed to unlock callback: " .. lerr
    end

    return val, cache_status, err
end

-- Get secret from cache or perform callback
function M:get(key, cb, ...)
    -- Key sanity check
    if type(key) ~= "string" then
        return nil, nil, "Key must be a string"
    end

    -- Look up key in cache
    local val, err = self.cache:get(key)

    -- Return key if found
    if val then
        return val, "HIT", nil
    end

    -- Create new lock
    local lock, err = resty_lock:new(self.lock)

    if not lock then
        return nil, nil, "Failed to create lock: " .. err
    end

    local elapsed, lerr = lock:lock(key)

    if not elapsed and lerr ~= "timeout" then
        return nil, nil, "Failed to acquire lock: " .. lerr
    end

    -- Check if another worker has populated cache
    local val, err = self.cache:get(key)

    if err then
        return unlock_and_ret(lock, nil, nil, err)
    elseif val then
        return unlock_and_ret(lock, val, "HIT", nil)
    end

    -- Perform callback
    local pok, perr, err = xpcall(cb, traceback, ...)

    if not pok then
        return unlock_and_ret(lock, nil, nil, "Callback threw an error: " .. tostring(perr))
    elseif err then
        return unlock_and_ret(lock, nil, nil, err)
    end

    -- Set callback value in cache
    local ok, err = self.cache:set(key, perr, self.expiration)

    if err then
        return unlock_and_ret(lock, nil, nil, err)
    end

    -- Return new value
    return unlock_and_ret(lock, perr, "EXPIRED", nil)
end

-- Lock and force update value
function M:update(key, cb, ...)
    -- Create new lock
    local lock, err = resty_lock:new(self.lock)

    if not lock then
        return nil, nil, "Failed to create lock: " .. err
    end

    local elapsed, lerr = lock:lock(key)

    if not elapsed and err ~= "timeout" then
        return nil, nil, "Failed to acquire lock: " .. err
    end

    -- Perform callback
    local pok, perr, err = xpcall(cb, traceback, ...)

    if not pok then
        return unlock_and_ret(lock, nil, nil, "Callback threw an error: " .. tostring(perr))
    elseif err then
        return unlock_and_ret(lock, nil, nil, err)
    end

    -- Set callback value in cache
    local ok, err = self.cache:set(key, perr, self.expiration)

    if err then
        return unlock_and_ret(lock, nil, nil, err)
    end

    -- Return new value
    return unlock_and_ret(lock, perr, "FORCED", nil)
end

return M