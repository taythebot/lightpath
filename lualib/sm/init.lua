local M = {}

function M.run(global_config)
	-- Load essential libraries
	local exit = require 'sm.utils.exit'
	local redis = require 'sm.utils.redis'
	local config_fetcher = require 'sm.utils.config_fetcher'
	local cache = require 'sm.utils.cache'
	local mlcache = require 'sm.utils.mlcache'
	-- local rate_limit = require('sm.utils.rate_limit').load(global_config)
	-- local sticky = require('sm.utils.sticky').load(global_config)
	-- local challenge = require('sm.utils.challenge').load(global_config)

	local log = ngx.log
	local ERR = ngx.ERR
	local OK = ngx.OK

	log(OK, '[Init] Staring initlization of modules')

	-- Initialize auto ssl
	-- local auto_ssl = (require 'resty.auto-ssl').new()

	-- auto_ssl:set('allow_domain', function(domain)
	-- 	return true
	-- end)

	-- auto_ssl:set('storage_adapter', 'resty.auto-ssl.storage_adapters.redis')
	-- auto_ssl:set('redis', {
	-- 	host = global_config['redis']['host'],
	-- 	port = global_config['redis']['port'],
	-- 	db = '1',
	-- 	prefix = 'auto-ssl'
	-- })

	-- auto_ssl:init()

	-- Initialize cache
	log(OK, '[Init] Initializing mlcache')
	
	local ok, err = mlcache.init(global_config['mlcache'])
	
	if not ok then
		log(ERR, '[Init] Failed to initialize mlcache: ' .. err)
	else
		log(ERR, '[Init] Mlcache successfully initialized')
	end
end

return M