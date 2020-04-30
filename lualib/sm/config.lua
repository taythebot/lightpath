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

_M.cache = {
	
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

-- Recaptcha tokens
_M.captcha = {
	standard_site_key = '6LeL-YYUAAAAAB-__M4vjZx1SVoJRQ_yqYqII05p',
	standard_secret_key = '6LeL-YYUAAAAAOVZP_pQw5INrvlUtzhoEzCLCG5l',
	invisible_site_key = '6Lcr-YYUAAAAABBZECIOUbkgP5vJZfH1LM74jjJ1',
	invisible_secret_key = '6Lcr-YYUAAAAAGtelIrqMaEfWZWifwlkAwjFi5Fa'
}

-- Rate limit storage table
_M.rate_limit_storage = 'rate_limit_storage'

-- Cookie name
_M.cookie = {
	sticky = '__smduid',
	challenge = 'sm_challenge',
	pass = 'sm_pass'
}

-- Challenge vault
_M.challenge = {
	aes_key = '?6X-jDDbN6!Xg5Pk9KNX89pcggG*8ue5',
	aes_salt = 'AE!Bze8K',
	hmac_secret = '-R9<wU_v7)X.hUt!p3py+W`q6Tv7zm;m' 
}

-- Pass vault
_M.pass = {
	aes_key = 'txM!WYgt6L-LrF@Nn&mg$HyyyB&pKr=n',
	aes_salt = 'W7y_-kSX',
	hmac_secret = 'mepaEHF=_BG2@MUMFtTFMc^+e=srCyhD' 
}

return _M