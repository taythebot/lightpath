local template = require 'resty.template'

local M = {}

function M.render(file, variables)
	return template.render(file, variables)
end

return M