local http = require "resty.http"
local cjson = require "cjson"

local M = {}
local _M = {}

function M.init(config)
    -- Sanity checks
    if type(config["endpoint"]) ~= "string" then
        return nil, "Endpoint must be a string"
    end

    if type(config["version"]) ~= "string" then
        return nil, "Version must be a string"
    end

    if type(config["header"]) ~= "boolean" then
        return nil, "Header option must be a boolean"
    end

    -- Set request headers
    local headers

    if config["header"] then
        headers = {
            ["X-Vault-Request"] = true
        }
    end

    _M.endpoint, _M.headers = config["endpoint"] .. "/" .. config["version"] .. "/", headers

    return true, nil
end

function M.get(path, key)
    -- Request secret from Vault agent
    local httpc = http:new()
    local res, err = httpc:request_uri(_M.endpoint .. path, {
        method = "GET",
        headers = _M.headers,
        keepalive_timeout = 60000,
        keepalive_pool = 20
    })

    if not res then
        return nil, "Error occurred while querying Vault: " .. err
    end

    if res.status == 403 then
        return nil, "Received 403 error from Vault"
    elseif res.status == 404 then
        return nil, "Secret not found in Vault"
    end

    local body = cjson.decode(res.body)

    if not body["data"]["data"][key] then
        return nil, "Key not found in response body from Vault"
    end

    return body["data"]["data"][key], nil
end

return M