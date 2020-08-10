local redis = require "resty.redis"
local error = require "sm.utils.error"

local M = {}
local _M = {}

-- Connect to Redis
function M.connect(config)
    -- Sanity checks
    if type(config["host"]) == "string" then
        return nil, error("Host must be a string")
    end

    if type(config["port"]) ~= "number" then
        return nil, error("Port must be a number")
    end

    if type(config["timeout"]) ~= "number" then
        return nil, error("Timeout must be a number")
    end

    local red = redis:new()

    red:set_timeout(timeout)

    local ok, err = red:connect(config["host"], config["port"])
    if err then
        return nil, error(err)
    end

    _M.redis = red

    return true, nil
end

-- Close connection
function M.close()
    if _M.redis then
        local ok, err = _M.redis:keepalive(10000, 100)
        if not ok then
            return nil, error(err)
        end
    end
end

-- Get value
function M.get(key)
    local res, err = _M.redis:get(key)
    if not res or res == ngx.null then
        return nil, error(err)
    end

    return res
end

-- Get all hash keys
function M.hgetall(key)
    local res, err = _M.redis:hgetall(key)
    if err then
        return nil, error(err)
    elseif not res or next(res) == nil then
        return nil
    end

    -- Reconstruct into table
    local final = {}
    for v = 1, #res, 2 do
        final[res[v]] = res[v + 1]
    end

    return final
end

return M