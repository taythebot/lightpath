local mlcache = require "resty.mlcache"
local error = require "lightpath.utils.error"

local shared = ngx.shared

local M = {}
local _M = {}

-- Initialize cache
function M.init(config)
    if type(config["number_of_instances"]) ~= "number" or config["number_of_instances"] < 1 then
        return nil, "[Mlcache] Number of instances must be a number and greater or equal to 1"
    end

    local mlcaches = {}
    local shm_names = {}

    -- Create 2 instances of mlcache per worker
    for i = 1, config["number_of_instances"] do
        local name = config["name"] .. "_" .. i
        local hit = config["dict_hit"] .. "_" .. i
        local miss = config["dict_miss"] .. "_" .. i

        -- Check if tables exist
        if not shared[hit] then
            return nil, "[Mlcache] Shared dictionary " .. hit .. " not found"
        end

        if not shared[miss] then
            return nil, "[Mlcache] Shared dictionary " .. miss .. " not found"
        end

        if shared[name] then
            local cache, err = mlcache.new(name, hit, {
                shm_miss = miss,
                shm_lock = config["dict_lock"], -- Mlcache instances can share the same lock dict
                lru_size = config["lru_size"],
                ttl = config["ttl"],
                neg_ttl = config["neg_ttl"],
                resurrect_ttl = config["resurrect_ttl"]
            })

            if not cache then
                return nil, "[Mlcache] Failed to initialize cache " .. name .. ": " .. err
            end

            -- logger.debug("[Mlcache] Cache '' .. name .. '' successfully initialized")

            mlcaches[i] = cache
            shm_names[i] = name
        else
            return nil, "[Mlcache] Failed to initialize mlcache instance " .. name
        end
    end

    _M = {
        mlcache = mlcaches[1],
        mlcaches = mlcaches,
        shm_names = shm_names
    }

    return true, nil
end

-- Fetch from cache with key
function M.get(key, callback, ...)
    if type(key) ~= "string" then
        return nil, nil, error("Key must be a string")
    end

    -- Get cache from mlcache
    local value, err, hit_level = _M.mlcache:get(key, nil, callback, ...)

    return value, hit_level, err
end

-- Set cache with key
function M.set(key, value)
    if type(key) ~= "string" then
        return nil, error("[Mlcache] Key must be a string")
    end

    -- Write function to delegate websites into different cache
    local shm_name = _M.shm_names[1]

    -- Prepare
    return ngx.shared[shm_name]:set(shm_name .. key, value)
end

return M