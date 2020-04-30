local M = {}

local template = require('resty.template')

function M.render(file, variables)
	local func = template.compile(file)
	local compiled = func(variables)
	return compiled
end

return M