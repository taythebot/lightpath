-- Load libraries
require 'sm.utils.exit'
require 'sm.utils.redis'
require 'sm.utils.config_fetcher'
require 'sm.utils.cache'

local config = require 'sm.config'
local mlcache = require 'sm.utils.mlcache'
local cache = require 'sm.purge.utils.cache'
local vault = require 'sm.purge.utils.vault'

local log = ngx.log
local ERR = ngx.ERR
local OK = ngx.OK
local shared = ngx.shared
local string_lower = string.lower
local server_id = os.getenv('SERVER_ID')

log(OK, '[Init] Staring initialization of modules')

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

-- Initialize Mlcache
log(OK, '[Init] Initializing Mlcache')

local ok, err = mlcache.init(config['mlcache'])

if not ok then
	log(ERR, '[Init] Failed to initialize Mlcache: ', err)
else
	log(OK, '[Init] Mlcache successfully initialized')
end

-- Initialize internal cache
log(OK, '[Init] Initializing internal cache')

local ok, err = cache.init(config['cache'], string_lower(server_id))

if not ok then
	log(ERR, '[Init] Failed to initialize internal cache: ', err)
else
	log(OK, '[Init] Internal cache successfully initialized')
end

-- Initialize Vault
log(OK, '[Init] Initializing Vault')

local ok, err = vault.init(config['vault'])

if not ok then
	log(ERR, '[Init] Failed to initialize Vault: ', err)
else
	log(OK, '[Init] Vault successfully initialized')
end

log(OK, '[Init] Initialization finished')