-- 03_build_analytics_table.sql
-- Builds the clean, analysis-ready table used by every later query.
-- Cost basis: A4A 2025 average cost per aircraft block minute ($98.41),
-- applied to all years so costs are in constant 2025 dollars.

CREATE SCHEMA IF NOT EXISTS analytics;

DROP TABLE IF EXISTS analytics.flights;

CREATE TABLE analytics.flights AS
WITH base AS (
    SELECT
        *,
        crs_dep_time::int                                  AS dep_hhmm,
        crs_arr_time::int                                  AS arr_hhmm,
        (crs_dep_time::int / 100) * 60 + (crs_dep_time::int % 100) AS dep_min_of_day,
        (crs_arr_time::int / 100) * 60 + (crs_arr_time::int % 100) AS arr_min_of_day
    FROM raw.flights
)
SELECT
    -- Date and time
    flight_date,
    year,
    month,
    day_of_week,                                  -- 1 = Monday ... 7 = Sunday
    (dep_hhmm / 100) % 24                         AS dep_hour,
    CASE
        WHEN (dep_hhmm / 100) % 24 BETWEEN 5  AND 8  THEN '1. Early Morning (5-9 AM)'
        WHEN (dep_hhmm / 100) % 24 BETWEEN 9  AND 11 THEN '2. Morning (9 AM-12 PM)'
        WHEN (dep_hhmm / 100) % 24 BETWEEN 12 AND 16 THEN '3. Afternoon (12-5 PM)'
        WHEN (dep_hhmm / 100) % 24 BETWEEN 17 AND 20 THEN '4. Evening (5-9 PM)'
        ELSE '5. Night (9 PM-5 AM)'
    END                                           AS time_of_day,

    -- Scheduled timestamps (local time at each airport)
    flight_date + make_interval(hours => dep_hhmm / 100, mins => dep_hhmm % 100)
                                                  AS sched_dep_ts,
    flight_date + make_interval(hours => arr_hhmm / 100, mins => arr_hhmm % 100)
        + CASE WHEN arr_min_of_day - dep_min_of_day < -300   -- crossed midnight
               THEN INTERVAL '1 day' ELSE INTERVAL '0' END
                                                  AS sched_arr_ts,

    -- Airline, aircraft, route
    airline,
    tail_number,
    flight_number,
    origin,
    dest,
    origin || '-' || dest                         AS route,
    origin_city,
    dest_city,
    distance,

    -- Status flags
    (cancelled = 1)                               AS is_cancelled,
    (diverted = 1)                                AS is_diverted,
    cancellation_code,
    (arr_del15 = 1)                               AS is_delayed,   -- NULL if cancelled

    -- Delay minutes
    dep_delay,
    arr_delay,
    dep_delay_minutes,
    arr_delay_minutes,

    -- Delay causes (minutes; blank = 0)
    COALESCE(carrier_delay, 0)                    AS carrier_delay,
    COALESCE(weather_delay, 0)                    AS weather_delay,
    COALESCE(nas_delay, 0)                        AS nas_delay,
    COALESCE(security_delay, 0)                   AS security_delay,
    COALESCE(late_aircraft_delay, 0)              AS late_aircraft_delay,

    -- Cost in dollars (constant 2025 dollars)
    ROUND((COALESCE(arr_delay_minutes, 0) * 98.41)::numeric, 2) AS delay_cost_usd
FROM base;

-- Index for chain tracing: each aircraft's flights in time order
CREATE INDEX idx_af_tail_time ON analytics.flights (tail_number, sched_dep_ts);
CREATE INDEX idx_af_origin    ON analytics.flights (origin);
CREATE INDEX idx_af_airline   ON analytics.flights (airline);

ANALYZE analytics.flights;

-- ---------- Quick check ----------
SELECT year,
       COUNT(*)                                  AS flights,
       ROUND(SUM(delay_cost_usd) / 1e9, 2)       AS delay_cost_billion_usd
FROM analytics.flights
GROUP BY year
ORDER BY year;