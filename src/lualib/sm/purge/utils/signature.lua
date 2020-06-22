local hmac = require 'resty.hmac'
local str = require 'resty.string'

local M = {}

function M.compute(secret, value)
	-- Sanity checks
	if type(secret) ~= 'string' then
		return nil, 'Secret must be a string'
	end

	if type(value) ~= 'string' then
		return nil, 'Value must be a string'
	end

	-- Compute hmac
	local signature = hmac:new(secret, hmac.ALGOS.SHA256):final(value)

	if not signature then
		return nil, 'Failed to compute hmac signature'
	end

	-- Return boolean comparison of given value and computed signature
	return str.to_hex(signature)
end

return M