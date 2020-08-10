local debug_getinfo = debug.getinfo
local table_insert = table.insert

local log = ngx.log
local ERR = ngx.ERR
local catcher_trace_level = 4

local function get_culprit(level)
    local culprit

    level = level + 1
    local info = debug_getinfo(level, "Snl")
    if info.name then
        culprit = info.name
    else
        culprit = info.short_src .. ":" .. info.linedefined
    end

    return culprit
end

local function backtrace(level)
    local frames = {}

    level = level + 1

    while true do
        local info = debug_getinfo(level, "Snl")
        if not info then
            break
        end

        table_insert(frames, 1, {
            filename = info.short_src,
            ["function"] = info.name,
            lineno = info.currentline,
        })

        level = level + 1
    end
    return { frames = frames }
end

-- error_catcher: used to catch an error from xpcall and return a correct
-- error message
local function error_catcher(err)
    return {
        message = err,
        culprit = get_culprit(catcher_trace_level),
        exception = { {
                          value = err,
                          stacktrace = backtrace(catcher_trace_level),
                      } },
    }
end

-- a wrapper around error_catcher that will return something even if
-- error_catcher itself crashes
return function(err)
    local ok, json_exception = pcall(error_catcher, err)
    if not ok then
        -- when failed, json_exception is error message
        log(ERR, "Failed to run exception catcher: ", json_exception)
        -- try to return something anyway (error message with no culprit and
        -- no stacktrace
        json_exception = {
            message = err,
            culprit = "???",
            exception = { { value = err } },
        }
    end

    return json_exception
end
