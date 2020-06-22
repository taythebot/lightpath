local _M = {}

-- Module power switch
_M.enabled = true

-- Development mode
_M.dev = true

-- Server identification
_M.server = {
	name = 'NY-1'
}

-- Redis options
_M.redis = {
	host = 'host.docker.internal',
	port = 6379,
	timeout = 1000,
	table = 0
}

-- Mlcache options
_M.mlcache = {
	number_of_instances = 2,
	name = 'mlcache',
	dict_hit = 'mlcache_hit',
	dict_miss = 'mlcache_miss',
	dict_lock = 'mlcache_lock',
	lru_size = 5e5,
	ttl = 30,
	neg_ttl = 300,
	resurrect_ttl = 30
}

-- Internal cache options
_M.cache = {
	cache_dict = 'internal_cache',
	lock_dict = 'internal_lock',
	expiration = 86400
}

-- Vault settings
_M.vault = {
	endpoint = 'http://host.docker.internal:8100',
	version = 'v1',
	header = true
}

return _M