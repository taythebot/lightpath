local M = {}

local new_timer = ngx.timer.at
local shared = ngx.shared
local log = ngx.log
local ERR = ngx.ERR
local pcall = pcall

local function do_check(dict)
	-- Get 20 keys
	local keys = dict:get_keys(20)

	-- Check if there are keys returned
	if next(keys) == nil then
		log(ERR, 'table is empty')
		return
	end

	-- Loop through
	for k,v in pairs(keys) do
		log(ERR, k, v)
	end

	log(ERR, 'type: ' , type(keys))

	-- Grab first key
	-- local value, err = dict.get([:0])

	-- if not value then
	-- 	return nil, 'Failed to grab key'
	-- end
	
	return
end

local check
check = function(premature, dict)
	if premature then
		return
	end

	-- Perform check
	local ok, err = pcall(do_check, dict)

	if not ok then
		log(ERR, 'Failed to perform task: ', err)
	end

	-- Create new timer
	local ok, err = new_timer(1, check, dict)

	if not ok and err ~= 'process exiting' then
		return log(ERR, 'Failed to create new timer: ', err)
	end
end

function M.init(shm)
	-- Check if dictionary exists
	local dict = shared[shm]

	if not dict then
		return nil, 'Shared dictionary "' .. shm .. '" not found'
	end

	-- Create initial timer
	local ok, err = new_timer(0, check, dict)

	if not ok then
		return nil, 'Failed to create initial timer: ' .. err
	end

	return true
end

return M