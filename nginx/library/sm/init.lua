local M = {}

function M.run(global_config)
	-- Load essential packages
	local logger = require('sm.utils.logger').load(global_config)
	local exit = require('sm.utils.exit').load(global_config)
	local rate_limit = require('sm.utils.rate_limit').load(global_config)
	local sticky = require('sm.utils.sticky').load(global_config)
	local challenge = require('sm.utils.challenge').load(global_config)

	-- Initialize auto ssl
	local auto_ssl = (require 'resty.auto-ssl').new()

	auto_ssl:set('allow_domain', function(domain)
		return true
	end)

	auto_ssl:set('storage_adapter', 'resty.auto-ssl.storage_adapters.redis')
	auto_ssl:set('redis', {
		host = global_config['redis']['host'],
		port = global_config['redis']['port'],
		db = '1',
		prefix = 'auto-ssl'
	})

	auto_ssl:init()

	-- Initialize cache
	local ledge = require('ledge/ledge')

	ledge.configure({
		redis_connector_params = {
			url = 'redis://' .. global_config['redis']['host'] .. ':' .. global_config['redis']['port'] .. '/2',
		}
	})

	ledge.set_handler_defaults({
		upstream_host = '127.0.0.1',
		upstream_port = 8080,
	})
end

return M