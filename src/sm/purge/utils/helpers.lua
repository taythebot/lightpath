local vault = require "sm.utils.vault"
local hmac = require "resty.hmac"
local str = require "resty.string"

local M = {}

local function compute_signature(secret, value)
    -- Sanity checks
    if type(secret) ~= "string" then
        return nil, "Secret must be a string"
    end

    if type(value) ~= "string" then
        return nil, "Value must be a string"
    end

    -- Compute hmac
    local signature = hmac:new(secret, hmac.ALGOS.SHA256):final(value)

    if not signature then
        return nil, "Failed to compute hmac signature"
    end

    -- Return boolean comparison of given value and computed signature
    return str.to_hex(signature)
end

function M.get_auth(path, key, server_id)
    local secret, err = vault.get(path, key)
    if not secret then
        return nil, "Failed to get secret from Vault: " .. err
    end

    -- Compute signature
    local signature, err = compute_signature(server_id, secret)
    if not signature then
        return nil, "Failed to compute signature: " .. err
    end

    -- Return combined secret and signature
    return secret .. "," .. signature, nil
end

function M.parse(value)
    -- Parse value
    local secret, signature = value:match("([^,]+),([^,]+)")

    return secret, signature
end

return M