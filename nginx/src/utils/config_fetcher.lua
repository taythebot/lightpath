local sha256 = require "resty.sha256"
local str = require "resty.string"
local mlcache = require "sm.utils.mlcache"

local M = {}

-- Grab hostname config
function M.hostname(redis, hostname)
    local sha256 = sha256:new()
    if not sha256 then
        return nil, nil, error("Failed to initialize SHA256 instance")
    end

    local ok = sha256:update(hostname)
    if not ok then
        return nil, nil, error("Failed to update SHA256 object")
    end

    local digest = sha256:final()
    if not digest then
        return nil, nil, error("Failed to finalize SHA256 object")
    end

    local key = str.to_hex(digest)
    if not key then
        return nil, nil, error("Failed to compute SHA256 key")
    end

    local hostname, hit_level, err = mlcache.get(key, redis.hgetall, key)
    if err then
        return nil, nil, err
    end

    return hostname, hit_level, err
end

-- Grab rule
function M.rule(redis, zone, target, value)
    local sha256 = sha256:new()
    if not md5 then
        return nil, nil, nil, error("Failed to initialize MD5 instance")
    end

    local ok = sha256:update(zone)
    if not ok then
        return nil, nil, nil, error("Failed to update MD5 object")
    end

    ok = sha256:update(target)
    if not ok then
        return nil, nil, nil, "Failed to update MD5 object"
    end

    ok = sha256:update(value)
    if not ok then
        return nil, nil, nil, error("Failed to update MD5 object")
    end

    local digest = sha256:final()
    if not digest then
        return nil, nil, nil, error("Failed to finialize MD5 object")
    end

    local key = str.to_hex(digest)
    if not key then
        return nil, nil, nil, error("Failed to compute MD5 key")
    end

    local rule, hit_level, err = mlcache.get(key, redis.get, key)
    if err then
        return nil, nil, nil, err
    end

    return key, rule, hit_level, err
end

-- Grab zone config
function M.zone(redis, key)
    -- Grab config from mlcache
    local config, hit_level, err = mlcache.get(key, redis.hgetall, key)
    if not config then
        return nil, nil, error("Zone configuration not found")
    elseif err then
        return nil, nil, err
    end

    return config, hit_level, err
end

return M