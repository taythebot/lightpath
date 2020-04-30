local cjson = require 'cjson'
local geo = require 'resty.maxmind'

local M = {}

function M:new(file)
	if not geo.initted() then
		geo.init(file)
	end

	return
end

function M:lookup(ip)
	local res, err = geo.lookup(ip)

	if not res then
		return nil, 'Failed to lookup ip address: ' .. err
	end

	return res
end

return M