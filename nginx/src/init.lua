-- Load libraries
require "lightpath.utils.exit"
require "lightpath.utils.redis"
require "lightpath.utils.config_fetcher"
require "lightpath.utils.cache"
require "lightpath.utils.internal_cache"
require "lightpath.purge.utils.helpers"

local config = require "lightpath.config"
local mlcache = require "lightpath.utils.mlcache"
-- local vault = require "lightpath.utils.vault"

local log = ngx.log
local ERR = ngx.ERR
local OK = ngx.OK

log(OK, "[Init] Staring initialization of modules")

-- Initialize auto ssl
-- local auto_ssl = (require "resty.auto-ssl").new()

-- auto_ssl:set("allow_domain", function(domain)
-- 	return true
-- end)

-- auto_ssl:set("storage_adapter", "resty.auto-ssl.storage_adapters.redis")
-- auto_ssl:set("redis", {
-- 	host = global_config["redis"]["host"],
-- 	port = global_config["redis"]["port"],
-- 	db = "1",
-- 	prefix = "auto-ssl"
-- })

-- auto_ssl:init()

-- Initialize Mlcache
log(OK, "[Init] Initializing Mlcache")

local ok, err = mlcache.init(config["mlcache"])

if not ok then
    log(ERR, "[Init] Failed to initialize Mlcache: ", err)
else
    log(OK, "[Init] Mlcache successfully initialized")
end

-- Initialize Vault
-- log(OK, "[Init] Initializing Vault")
--
-- local ok, err = vault.init(config["vault"])
--
-- if not ok then
--     log(ERR, "[Init] Failed to initialize Vault: ", err)
-- else
--     log(OK, "[Init] Vault successfully initialized")
-- end

log(OK, "[Init] Initialization finished")
