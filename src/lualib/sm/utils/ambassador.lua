-- Load essential libraries
local http = require 'resty.http'
local cjson = require 'cjson.safe'

local setmetatable = setmetatable

local M = {}
local mt = { __index = M }

function M.new(config)
	-- Sanity checks
	if type(config['endpoint']) ~= 'string' then
		return nil, 'Endpoint must be a string'
	end

	local self = {
		endpoint = config['endpoint'],
	}

	return setmetatable(self, mt)
end

function M:get_certificate(token, id)
	local httpc = http:new()
	local res, err = httpc:request_uri(self.endpoint .. '/certificates/' .. id, {
		method = 'GET',
		headers = {
			Accept = 'application/json',
			Authorization = 'Bearer ' .. token
		},
		keepalive_timeout = 60000,
        keepalive_pool = 20
	})

	if not res then
		return nil, nil, 'Error occurred while querying Ambassador: ' .. err
	end

	if res.status == 401 then
		return nil, true, 'Received 401 error from Ambassador, expired token'
	elseif res.status == 403 then
		return nil, true, 'Received 403 error from Ambassador, permission denied'
	end

	return cjson.decode(res.body), nil, nil
end

return M