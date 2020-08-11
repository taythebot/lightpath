return {
	redis = {
		host = "host.docker.internal",
		port = 6379,
		timeout = 1000,
		table = 0
	},
	mlcache = {
		number_of_instances = 2,
		name = "mlcache",
		dict_hit = "mlcache_hit",
		dict_miss = "mlcache_miss",
		dict_lock = "mlcache_lock",
		lru_size = 5e5,
		ttl = 30,
		neg_ttl = 300,
		resurrect_ttl = 30
	},
	internal = {
		cache_dict = "internal_cache",
		lock_dict = "internal_lock",
		expiration = 86400
	},
	vault = {
		endpoint = "http://host.docker.internal:8100",
		version = "v1",
		header = true
	},
	ssl = {
		cache_dict = "ssl_cache",
		lock_dict = "ssl_lock",
		expiration = 1800
	},
	ambassador = {
		endpoint = "http://host.docker.internal:3002/v1",
	}
}
