-- Copyright (C) CloudFlare Inc.
--
-- Generate memcached getter/setter pair from config


local _M = {
     version = '0.01',
}


local memcached = require "resty.memcached"
local resty_lock = require "resty.lock"
local str_format = string.format
local sleep = ngx.sleep


local DEBUG = ngx.config.debug


local function id(a)
     return a
end


local memc_config = {
     key_transform = { id, id },
}


local default_fetch_retries = 1
local default_store_retries = 1
local default_retry_delay = 100 -- msec
local default_store_ttl = 0 -- no expiration


function _M.gen_memc_methods (opts)
    local error_log = opts.error_logger
    local dlog = opts.debug_logger
    local warn = opts.warn_logger
    local tag = opts.tag

    local disable_shdict = opts.disable_shdict
    local shdict_set = opts.shdict_set
    local shdict_get = opts.shdict_get

    local locks_shdict_name = opts.locks_shdict_name
    local memc_timeout = opts.memc_timeout
    local pool_size = opts.memc_conn_pool_size
    local max_idle_time = opts.memc_conn_max_idle_time
    local memc_host = opts.memc_host
    local memc_port = opts.memc_port
    local fetch_retries = opts.memc_fetch_retries or default_fetch_retries
    local fetch_retry_delay = opts.memc_fetch_retry_delay or default_retry_delay
    fetch_retry_delay = fetch_retry_delay / 1000  -- sec
    local store_retries = opts.memc_store_retries or default_store_retries
    local store_retry_delay = opts.memc_store_retry_delay or default_retry_delay
    store_retry_delay = store_retry_delay / 1000  -- sec
    local store_ttl = opts.store_ttl or default_store_ttl

    local lock_opts = {
        exptime = memc_timeout * 2 / 1000,  -- sec
        timeout = memc_timeout * 1.2 / 1000,  -- sec
        step = 0.001,  -- sec
        max_step = 0.1,  -- sec
    }

    local function init_memc (ctx)
        local memc = ctx[tag]

        if not memc then
            local err
            memc, err = memcached:new(memc_config)
            if not memc then
                return nil, err
            end

            ctx[tag] = memc

            memc:set_timeout(memc_timeout)
        end

        -- we rely on the user to call release_memc() upon every invocation
        -- of init_memc().

        local ok, err = memc:connect(memc_host, memc_port)
        if not ok then
            return nil, err
        end

        if DEBUG then dlog(ctx, "connected to memc") end

        return memc
    end

    local function release_memc(ctx, memc)
        local ok, err = memc:set_keepalive(max_idle_time, pool_size)
        if not ok then
            warn(ctx, "failed to put connection for ", tag,
                 " into the pool: ", err)
        end
    end

    local function fetch_key_from_memc(ctx, key)

        local cached, stale = shdict_get(ctx, key)
        if cached and not stale then
            if cached == "" then
                return nil
            end

            return cached
        end

        -- cache lock

        local lock
        if not disable_shdict then
            local err
            lock, err = resty_lock:new(locks_shdict_name, lock_opts)
            if not lock then
                error_log(ctx, "failed to create a lock for memc queries: ",
                          err)
                return nil
            end

            local elapsed, err = lock:lock(key)
            if elapsed then
                -- lock is acquired

                -- check if other timers have already insert a fresh result
                -- into the shdict.

                local cached, stale = shdict_get(ctx, key)
                if cached and not stale then
                    if DEBUG then
                        dlog(ctx, "some other timer just inserted a fresh memc "
                              .. 'result into shdict for key "', key, '"')
                    end
                    if lock then
                        lock:unlock()
                    end

                    if cached == "" then
                        -- negative hit
                        return nil
                    end

                    return cached
                end

            else
                error_log(ctx, 'failed to acquire cache lock on key "', key,
                             '"; proceed anyway')
            end
        end

        if cached == "" then
            -- negative hit
            cached = nil
        end

        -- here we intentionally duplicate the code a bit to avoid
        -- inner loops with low iteration count on normal code
        -- path.

        local memc, err = init_memc(ctx)
        if not memc then
            if lock then
                lock:unlock()
            end
            return cached, "failed to init " .. tag .. ": " .. (err or "")
        end

        local res, flags, err = memc:get(key)
        if not res and err then

            for i = 1, fetch_retries do

                if fetch_retry_delay > 0 then
                    if DEBUG then
                        dlog(ctx, "waiting for ", fetch_retry_delay,
                              " sec before the next retry #", i)
                    end
                    sleep(fetch_retry_delay)
                end

                warn("retrying fetch #", i, " from ", tag,
                      ' due to error "', err, '"')

                memc, err = init_memc(ctx)
                if not memc then
                    -- "fetch retries" are not "connect retries" anyway:
                    if lock then
                        lock:unlock()
                    end
                    return cached, "failed to init " .. tag .. ": "
                           .. (err or "")
                end

                res, flags, err = memc:get(key)
                if res or not err then
                    break
                end
            end

            if err then
                if lock then
                    lock:unlock()
                end

                local msg = str_format('failed to get key "%s" from %s: %s',
                                              key, tag, err or "")
                return cached, msg
            end
        end

        release_memc(ctx, memc)

        shdict_set(ctx, key, res or "")

        if lock then
            lock:unlock()
        end

        return res
    end

    local function store_key_to_memc(ctx, key, value, ttl)
        shdict_set(ctx, key, value or "", ttl)

        ttl = ttl or store_ttl

        local lock
        if not disable_shdict then
            local err
            lock, err = resty_lock:new(locks_shdict_name, lock_opts)
            if not lock then
                error_log(ctx, "failed to create a lock for memc queries: ",
                          err)
                return nil
            end

            local elapsed, err = lock:lock(key)
            if elapsed then
                -- lock is acquired
            else
                error_log(ctx, 'failed to acquire cache lock on key "', key,
                             '"; proceed anyway')
                return nil
            end
        end

        local memc, err = init_memc(ctx)
        if not memc then
            if lock then
                lock:unlock()
            end

            error_log(ctx, "failed to init ", tag, ": ", err,
                      ', dst: ', memc_host, ':', memc_port)
            return nil
        end

        local ok, err = memc:set(key, value, ttl)
        if not ok and err then

            for i = 1, store_retries do

                if store_retry_delay > 0 then
                    if DEBUG then
                        dlog(ctx, "waiting for ", store_retry_delay,
                              " sec before the next retry #", i)
                    end
                    sleep(store_retry_delay)
                end

                warn("retrying store #", i, " from ", tag,
                      ' due to error "', err, '"')

                memc, err = init_memc(ctx)
                if memc then
                    ok, err = memc:set(key, value, ttl)
                    if ok or not err then
                        break
                    end
                end
            end

            if err then
                if lock then
                    lock:unlock()
                end

                error_log(ctx, 'failed to store key "', key, '" to ', tag,
                          ': ', err)
                return nil
            end
        end

        release_memc(ctx, memc)

        if lock then
            lock:unlock()
        end

        return true
    end

    return fetch_key_from_memc, store_key_to_memc
end


return _M
