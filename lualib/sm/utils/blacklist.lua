local ngx_re = require 'ngx.re'
local cjson = require 'cjson'

local M = {}

-- Check if target is present in given list
function M.check_list(list, target)
	local parsed, err = ngx_re.split(list, ',')

	if not parsed then
		return nil, 'Error occurred while parsing IP blacklist: ' .. err
	end

	for _, v in pairs(parsed) do
		if v == target then
			return nil, nil
		end
	end

	return true, nil
end

return M