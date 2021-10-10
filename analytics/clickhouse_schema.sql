--  Create Database
CREATE DATABASE IF NOT EXISTS analytics;

-- Master table
CREATE TABLE IF NOT EXISTS analytics.zones (
	request_id FixedString(32),
	zone_id FixedString(32),
	remote_addr String,
	request_date DateTime('UTC'),
	request_method String,
	request_time Float32,
	bytes UInt64,
	host String,
	request_uri String,
	status UInt16,
	http_referer Nullable(String),
	user_agent String,
	cache_status String,
	cache_ttl UInt16,
	cache_key FixedString(32),
	server_id String,
	server_colo FixedString(2),
	compression String,
	request_country FixedString(2),
	request_asn String,
	rule_id Nullable(FixedString(32)),
	created_at DEFAULT toDateTime(now(), 'UTC')
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(request_date)
ORDER BY (zone_id, created_at);

-- Daily aggregation table
CREATE TABLE IF NOT EXISTS analytics.zones_daily (
    date DateTime('UTC'),
    zone_id FixedString(32),
    requests_total UInt64,
    bytes_total Float32,
    unique_visitors UInt64,
    requests_cache_hit UInt64,
    requests_cache_miss UInt64,
    bytes_cache_hit UInt64,
    bytes_cache_miss UInt64,
    statusMap Nested(code UInt16, count UInt64),
    requests_countryMap Nested(country FixedString(2), count UInt64),
    bytes_countryMap Nested(country String, count UInt64),
    requests_coloMap Nested(colo FixedString(2), count UInt64),
    bytes_coloMap Nested(colo String, count UInt64),
    requests_uriMap Nested(uri String, bytes UInt64, requests UInt64, time Float32, cache_hits UInt64)
) ENGINE = SummingMergeTree()
PARTITION BY toMonday(date)
ORDER BY (zone_id, date);

-- Daily aggregation materialized view
CREATE MATERIALIZED VIEW IF NOT EXISTS analytics.zones_daily_mv
to analytics.zones_daily
AS SELECT
    zone.date AS date,
    zone.zone_id AS zone_id,
    zone.requests_total AS requests_total,
    zone.bytes_total AS bytes_total,
    zone.unique_visitors AS unique_visitors,
    zone.statuses_unique AS `statusMap.code`,
    zone.statuses_count AS `statusMap.count`,
    cache_hit.count AS `requests_cache_hit`,
    cache_hit.bytes AS `bytes_cache_hit`,
    cache_miss.count AS `requests_cache_miss`,
    cache_miss.bytes AS `bytes_cache_miss`,
    country.countries AS `requests_countryMap.country`,
    country.requests AS `requests_countryMap.count`,
    country.countries AS `bytes_countryMap.country`,
    country.bytes AS `bytes_countryMap.count`,
    colo.colos AS `requests_coloMap.colo`,
    colo.requests AS `requests_coloMap.count`,
    colo.colos AS `bytes_coloMap.colo`,
    colo.bytes AS `bytes_coloMap.count`,
    request_uris.uris AS `requests_uriMap.uri`,
    request_uris.bytes AS `requests_uriMap.bytes`,
    request_uris.requests AS `requests_uriMap.requests`,
    request_uris.times AS `requests_uriMap.time`,
    request_uris.cache_hits AS `requests_uriMap.cache_hits`
FROM
    (
        SELECT
            toStartOfDay(request_date) AS date,
            zone_id,
            count() AS requests_total,
            sum(bytes) AS bytes_total,
            uniqExact(remote_addr) AS unique_visitors,
            groupArray(status) AS statuses,
            arrayReduce('groupUniqArray', statuses) AS statuses_unique,
            arrayMap(x -> countEqual(statuses, x), statuses_unique) AS statuses_count
        FROM analytics.zones
        GROUP BY (zone_id, date)
        ORDER BY (zone_id, date)
    ) AS zone
    ANY LEFT JOIN
    (
        SELECT
            toStartOfDay(request_date) AS date,
            zone_id,
            COUNT() AS count,
            sum(bytes) AS bytes
        FROM analytics.zones
        WHERE cache_status = 'HIT'
        GROUP BY (zone_id, date)
    ) AS cache_hit
    ON zone.date = cache_hit.date
    ANY LEFT JOIN
    (
        SELECT
            toStartOfDay(request_date) AS date,
            zone_id,
            COUNT() AS count,
            sum(bytes) AS bytes
        FROM analytics.zones
        WHERE cache_status != 'HIT'
        GROUP BY (zone_id, date)
    ) AS cache_miss
    ON zone.date = cache_miss.date
    ANY LEFT JOIN
    (
        SELECT
            date AS date,
            groupArray(request_country) AS countries,
            groupArray(bytes) AS bytes,
            groupArray(requests) AS requests
        FROM
        (
            SELECT
                toStartOfDay(request_date) AS date,
                request_country,
                sum(bytes) AS bytes,
                count() AS requests
            FROM analytics.zones
            GROUP BY (request_country, date)
        )
        GROUP BY date
    ) AS country
    ON zone.date = country.date
    ANY LEFT JOIN
     (
        SELECT
            date,
            groupArray(server_colo) AS colos,
            groupArray(bytes) AS bytes,
            groupArray(requests) as requests
        FROM
        (
            SELECT
                toStartOfDay(request_date) AS date,
                server_colo,
                sum(bytes) AS bytes,
                count() AS requests
            FROM analytics.zones
            GROUP BY (server_colo, date)
        )
        GROUP BY date
    ) AS colo
    ON zone.date = colo.date
    ANY LEFT JOIN
    (
        SELECT
            date,
            groupArray(request_uri) AS uris,
            groupArray(bytes) AS bytes,
            groupArray(requests) AS requests,
            groupArray(times) AS times,
            groupArray(cache_hits) as cache_hits
        FROM
        (
            SELECT
                toStartOfDay(request_date) AS date,
                path(request_uri) as request_uri,
                sum(bytes) AS bytes,
                count() AS requests,
                avg(request_time) AS times,
                countEqual(groupArray(cache_status), 'HIT') as cache_hits
            FROM analytics.zones
            GROUP BY (request_uri, date)
            LIMIT 30
        )
        GROUP BY date
    ) AS request_uris
    ON zone.date = request_uris.date
ORDER BY (zone_id, date);

-- Weekly aggregation table
CREATE TABLE IF NOT EXISTS analytics.zones_weekly (
    date DateTime('UTC'),
    zone_id FixedString(32),
    requests_total UInt64,
    bytes_total Float32,
    unique_visitors UInt64,
    requests_cache_hit UInt64,
    requests_cache_miss UInt64,
    bytes_cache_hit UInt64,
    bytes_cache_miss UInt64,
    statusMap Nested(code UInt16, count UInt64),
    requests_countryMap Nested(country FixedString(2), count UInt64),
    bytes_countryMap Nested(country String, count UInt64),
    requests_coloMap Nested(colo FixedString(2), count UInt64),
    bytes_coloMap Nested(colo String, count UInt64),
    requests_uriMap Nested(uri String, bytes UInt64, requests UInt64, time Float32, cache_hits UInt64)
) ENGINE = SummingMergeTree()
PARTITION BY toYYYYMM(date)
ORDER BY (zone_id, date);

-- Weekly aggregation materialized view
CREATE MATERIALIZED VIEW IF NOT EXISTS analytics.zones_weekly_mv
to analytics.zones_weekly
AS SELECT
    zone.date AS date,
    zone.zone_id AS zone_id,
    zone.requests_total AS requests_total,
    zone.bytes_total AS bytes_total,
    zone.unique_visitors AS unique_visitors,
    zone.statuses_unique AS `statusMap.code`,
    zone.statuses_count AS `statusMap.count`,
    cache_hit.count AS `requests_cache_hit`,
    cache_hit.bytes AS `bytes_cache_hit`,
    cache_miss.count AS `requests_cache_miss`,
    cache_miss.bytes AS `bytes_cache_miss`,
    country.countries AS `requests_countryMap.country`,
    country.requests AS `requests_countryMap.count`,
    country.countries AS `bytes_countryMap.country`,
    country.bytes AS `bytes_countryMap.count`,
    colo.colos AS `requests_coloMap.colo`,
    colo.requests AS `requests_coloMap.count`,
    colo.colos AS `bytes_coloMap.colo`,
    colo.bytes AS `bytes_coloMap.count`,
    request_uris.uris AS `requests_uriMap.uri`,
    request_uris.bytes AS `requests_uriMap.bytes`,
    request_uris.requests AS `requests_uriMap.requests`,
    request_uris.times AS `requests_uriMap.time`,
    request_uris.cache_hits AS `requests_uriMap.cache_hits`
FROM
    (
        SELECT
            toMonday(request_date) AS date,
            zone_id,
            count() AS requests_total,
            sum(bytes) AS bytes_total,
            uniqExact(remote_addr) AS unique_visitors,
            groupArray(status) AS statuses,
            arrayReduce('groupUniqArray', statuses) AS statuses_unique,
            arrayMap(x -> countEqual(statuses, x), statuses_unique) AS statuses_count
        FROM analytics.zones
        GROUP BY (zone_id, date)
        ORDER BY (zone_id, date)
    ) AS zone
    ANY LEFT JOIN
    (
        SELECT
            toMonday(request_date) AS date,
            zone_id,
            COUNT() AS count,
            sum(bytes) AS bytes
        FROM analytics.zones
        WHERE cache_status = 'HIT'
        GROUP BY (zone_id, date)
    ) AS cache_hit
    ON zone.date = cache_hit.date
    ANY LEFT JOIN
    (
        SELECT
            toMonday(request_date) AS date,
            zone_id,
            COUNT() AS count,
            sum(bytes) AS bytes
        FROM analytics.zones
        WHERE cache_status != 'HIT'
        GROUP BY (zone_id, date)
    ) AS cache_miss
    ON zone.date = cache_miss.date
    ANY LEFT JOIN
    (
        SELECT
            date AS date,
            groupArray(request_country) AS countries,
            groupArray(bytes) AS bytes,
            groupArray(requests) AS requests
        FROM
        (
            SELECT
                toMonday(request_date) AS date,
                request_country,
                sum(bytes) AS bytes,
                count() AS requests
            FROM analytics.zones
            GROUP BY (request_country, date)
        )
        GROUP BY date
    ) AS country
    ON zone.date = country.date
    ANY LEFT JOIN
     (
        SELECT
            date,
            groupArray(server_colo) AS colos,
            groupArray(bytes) AS bytes,
            groupArray(requests) as requests
        FROM
        (
            SELECT
                toMonday(request_date) AS date,
                server_colo,
                sum(bytes) AS bytes,
                count() AS requests
            FROM analytics.zones
            GROUP BY (server_colo, date)
        )
        GROUP BY date
    ) AS colo
    ON zone.date = colo.date
    ANY LEFT JOIN
    (
        SELECT
            date,
            groupArray(request_uri) AS uris,
            groupArray(bytes) AS bytes,
            groupArray(requests) AS requests,
            groupArray(times) AS times,
            groupArray(cache_hits) as cache_hits
        FROM
        (
            SELECT
                toMonday(request_date) AS date,
                path(request_uri) as request_uri,
                sum(bytes) AS bytes,
                count() AS requests,
                avg(request_time) AS times,
                countEqual(groupArray(cache_status), 'HIT') as cache_hits
            FROM analytics.zones
            GROUP BY (request_uri, date)
            LIMIT 30
        )
        GROUP BY date
    ) AS request_uris
    ON zone.date = request_uris.date
ORDER BY (zone_id, date);

-- Monthly aggregation table
CREATE TABLE IF NOT EXISTS analytics.zones_monthly (
    date DateTime('UTC'),
    zone_id FixedString(32),
    requests_total UInt64,
    bytes_total Float32,
    unique_visitors UInt64,
    requests_cache_hit UInt64,
    requests_cache_miss UInt64,
    bytes_cache_hit UInt64,
    bytes_cache_miss UInt64,
    statusMap Nested(code UInt16, count UInt64),
    requests_countryMap Nested(country FixedString(2), count UInt64),
    bytes_countryMap Nested(country String, count UInt64),
    requests_coloMap Nested(colo FixedString(2), count UInt64),
    bytes_coloMap Nested(colo String, count UInt64),
    requests_uriMap Nested(uri String, bytes UInt64, requests UInt64, time Float32, cache_hits UInt64)
) ENGINE = SummingMergeTree()
PARTITION BY toYear(date)
ORDER BY (zone_id, date);

-- Monthly aggregation materialized view
CREATE MATERIALIZED VIEW IF NOT EXISTS analytics.zones_monthly_mv
to analytics.zones_monthly
AS SELECT
    zone.date AS date,
    zone.zone_id AS zone_id,
    zone.requests_total AS requests_total,
    zone.bytes_total AS bytes_total,
    zone.unique_visitors AS unique_visitors,
    zone.statuses_unique AS `statusMap.code`,
    zone.statuses_count AS `statusMap.count`,
    cache_hit.count AS `requests_cache_hit`,
    cache_hit.bytes AS `bytes_cache_hit`,
    cache_miss.count AS `requests_cache_miss`,
    cache_miss.bytes AS `bytes_cache_miss`,
    country.countries AS `requests_countryMap.country`,
    country.requests AS `requests_countryMap.count`,
    country.countries AS `bytes_countryMap.country`,
    country.bytes AS `bytes_countryMap.count`,
    colo.colos AS `requests_coloMap.colo`,
    colo.requests AS `requests_coloMap.count`,
    colo.colos AS `bytes_coloMap.colo`,
    colo.bytes AS `bytes_coloMap.count`,
    request_uris.uris AS `requests_uriMap.uri`,
    request_uris.bytes AS `requests_uriMap.bytes`,
    request_uris.requests AS `requests_uriMap.requests`,
    request_uris.times AS `requests_uriMap.time`,
    request_uris.cache_hits AS `requests_uriMap.cache_hits`
FROM
    (
        SELECT
            toStartOfMonth(request_date) AS date,
            zone_id,
            count() AS requests_total,
            sum(bytes) AS bytes_total,
            uniqExact(remote_addr) AS unique_visitors,
            groupArray(status) AS statuses,
            arrayReduce('groupUniqArray', statuses) AS statuses_unique,
            arrayMap(x -> countEqual(statuses, x), statuses_unique) AS statuses_count
        FROM analytics.zones
        GROUP BY (zone_id, date)
        ORDER BY (zone_id, date)
    ) AS zone
    ANY LEFT JOIN
    (
        SELECT
            toStartOfMonth(request_date) AS date,
            zone_id,
            COUNT() AS count,
            sum(bytes) AS bytes
        FROM analytics.zones
        WHERE cache_status = 'HIT'
        GROUP BY (zone_id, date)
    ) AS cache_hit
    ON zone.date = cache_hit.date
    ANY LEFT JOIN
    (
        SELECT
            toStartOfMonth(request_date) AS date,
            zone_id,
            COUNT() AS count,
            sum(bytes) AS bytes
        FROM analytics.zones
        WHERE cache_status != 'HIT'
        GROUP BY (zone_id, date)
    ) AS cache_miss
    ON zone.date = cache_miss.date
    ANY LEFT JOIN
    (
        SELECT
            date AS date,
            groupArray(request_country) AS countries,
            groupArray(bytes) AS bytes,
            groupArray(requests) AS requests
        FROM
        (
            SELECT
                toStartOfMonth(request_date) AS date,
                request_country,
                sum(bytes) AS bytes,
                count() AS requests
            FROM analytics.zones
            GROUP BY (request_country, date)
        )
        GROUP BY date
    ) AS country
    ON zone.date = country.date
    ANY LEFT JOIN
     (
        SELECT
            date,
            groupArray(server_colo) AS colos,
            groupArray(bytes) AS bytes,
            groupArray(requests) as requests
        FROM
        (
            SELECT
                toStartOfMonth(request_date) AS date,
                server_colo,
                sum(bytes) AS bytes,
                count() AS requests
            FROM analytics.zones
            GROUP BY (server_colo, date)
        )
        GROUP BY date
    ) AS colo
    ON zone.date = colo.date
    ANY LEFT JOIN
    (
        SELECT
            date,
            groupArray(request_uri) AS uris,
            groupArray(bytes) AS bytes,
            groupArray(requests) AS requests,
            groupArray(times) AS times,
            groupArray(cache_hits) as cache_hits
        FROM
        (
            SELECT
                toStartOfMonth(request_date) AS date,
                path(request_uri) as request_uri,
                sum(bytes) AS bytes,
                count() AS requests,
                avg(request_time) AS times,
                countEqual(groupArray(cache_status), 'HIT') as cache_hits
            FROM analytics.zones
            GROUP BY (request_uri, date)
            LIMIT 30
        )
        GROUP BY date
    ) AS request_uris
    ON zone.date = request_uris.date
ORDER BY (zone_id, date);