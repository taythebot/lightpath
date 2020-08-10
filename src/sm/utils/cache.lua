local ngx_re = require "ngx.re"

local ngx_unescape_uri = ngx.unescape_uri

local log = ngx.log
local OK = ngx.OK
local ERR = ngx.ERR

local M = {}

-- Sort request uri args
local function sort_args(input)
    local args_table = input
    local args_name = {}
    local newargs = {}

    for name, value in pairs(args_table) do
        if type(value) == "table" then
            for k, v in pairs(value) do
                table.insert(newargs, name .. "=" .. value[k])
            end
        else
            table.insert(args_name, name)
        end
    end

    for _, name in ipairs(args_name) do
        -- Lowercase and escape uri
        table.insert(newargs, string.lower(ngx_unescape_uri(name)) .. "=" .. string.lower(ngx_unescape_uri(args_table[name])))
    end

    table.sort(newargs) --Sort the table into order

    local output = table.concat(newargs, "&")

    return output --set the args to be the output
end

-- Create cache key
function M.create_key(zone, uri, uri_args, cache_query)
    local key = zone
    local slice_range = ngx.var.slice_range or nil

    if cache_query == "1" then
        -- Ignore query string
        if next(uri_args) ~= nil then
            -- Get file path without uri
            local res, err = ngx_re.split(uri, "^(.*)\\?(.*)$")

            key = key .. res[2] or uri
        else
            key = key .. uri
        end
    elseif cache_query == "2" then
        -- Sorted query string
        if next(uri_args) ~= nil then
            -- Sort query string
            local sorted_args = sort_args(uri_args)

            -- Get file path without uri
            local res, err = ngx_re.split(uri, "^(.*)\\?(.*)$")

            if res then
                key = key .. res[2] .. "?" .. sorted_args
            else
                key = key .. uri
            end
        else
            key = key .. uri
        end
    else
        -- Use same query string and fallback
        key = key .. uri
    end

    -- Add byte range
    if slice_range then
        key = key .. slice_range
    end

    return key
end

return M