-- 09_dashboard_tables.sql
-- Small, dashboard-ready summary tables for Power BI.
CREATE SCHEMA IF NOT EXISTS dashboard;

-- 1. Headline KPIs (one row)
DROP TABLE IF EXISTS dashboard.headline;
CREATE TABLE dashboard.headline AS
SELECT
    (SELECT COUNT(*) FROM analytics.flights)                               AS total_flights,
    (SELECT ROUND(SUM(delay_cost_usd) / 1e9, 2) FROM analytics.flights)    AS delay_cost_billion,
    (SELECT COUNT(*) FROM analytics.delay_chains)                          AS total_chains,
    (SELECT ROUND(100.0 * SUM(total_delay_min - starter_delay_min)
                  / SUM(total_delay_min), 1) FROM analytics.delay_chains)  AS pct_delay_inherited,
    (SELECT ROUND(SUM(total_cost_usd) / 1e9, 2) FROM analytics.delay_chains) AS chain_cost_billion;

-- 2. Yearly KPIs and delay causes
DROP TABLE IF EXISTS dashboard.yearly;
CREATE TABLE dashboard.yearly AS
SELECT
    year::text                                                     AS year,
    COUNT(*)                                                       AS flights,
    ROUND(100.0 * (1 - AVG(is_delayed::int)), 1)                   AS otp_pct,
    ROUND(100.0 * AVG(is_cancelled::int), 2)                       AS cancel_pct,
    ROUND(SUM(delay_cost_usd) / 1e9, 2)                            AS delay_cost_billion,
    ROUND(SUM(delay_cost_usd) / COUNT(*), 0)                       AS delay_cost_per_flight,
    ROUND(SUM(carrier_delay)::numeric / 1e6, 2)                    AS carrier_delay_min_m,
    ROUND(SUM(weather_delay)::numeric / 1e6, 2)                    AS weather_delay_min_m,
    ROUND(SUM(nas_delay)::numeric / 1e6, 2)                        AS nas_delay_min_m,
    ROUND(SUM(security_delay)::numeric / 1e6, 2)                   AS security_delay_min_m,
    ROUND(SUM(late_aircraft_delay)::numeric / 1e6, 2)              AS late_aircraft_delay_min_m
FROM analytics.flights
GROUP BY year
ORDER BY year;

-- 3. Monthly trend
DROP TABLE IF EXISTS dashboard.monthly;
CREATE TABLE dashboard.monthly AS
SELECT
    make_date(year::int, month::int, 1)                            AS month_start,
    COUNT(*)                                                       AS flights,
    ROUND(100.0 * (1 - AVG(is_delayed::int)), 1)                   AS otp_pct,
    ROUND(100.0 * AVG(is_cancelled::int), 2)                       AS cancel_pct,
    ROUND(SUM(delay_cost_usd) / 1e6, 1)                            AS delay_cost_million
FROM analytics.flights
GROUP BY year, month
ORDER BY 1;

-- 4. Airlines
DROP TABLE IF EXISTS dashboard.airlines;
CREATE TABLE dashboard.airlines AS
WITH f AS (
    SELECT airline,
           COUNT(*) FILTER (WHERE NOT is_cancelled)                AS flights,
           ROUND(100.0 * (1 - AVG(is_delayed::int)), 1)            AS otp_pct
    FROM analytics.flights
    GROUP BY airline
),
c AS (
    SELECT start_airline                                           AS airline,
           COUNT(*)                                                AS chains,
           AVG((downstream_flights > 0)::int)                      AS spread,
           AVG(delay_multiplier)                                   AS mult,
           SUM(total_cost_usd)                                     AS cost
    FROM analytics.delay_chains
    GROUP BY start_airline
)
SELECT
    f.airline                                                      AS code,
    CASE f.airline
        WHEN 'AA' THEN 'American'   WHEN 'DL' THEN 'Delta'
        WHEN 'UA' THEN 'United'     WHEN 'WN' THEN 'Southwest'
        WHEN 'AS' THEN 'Alaska'     WHEN 'B6' THEN 'JetBlue'
        WHEN 'NK' THEN 'Spirit'     WHEN 'F9' THEN 'Frontier'
        WHEN 'G4' THEN 'Allegiant'  WHEN 'HA' THEN 'Hawaiian'
        WHEN 'OO' THEN 'SkyWest'    WHEN 'YX' THEN 'Republic'
        WHEN 'MQ' THEN 'Envoy'      WHEN '9E' THEN 'Endeavor'
        WHEN 'OH' THEN 'PSA'        WHEN 'YV' THEN 'Mesa'
        WHEN 'QX' THEN 'Horizon'    ELSE f.airline
    END                                                            AS airline,
    f.flights,
    f.otp_pct,
    c.chains,
    ROUND(1000.0 * c.chains / f.flights, 1)                        AS chains_per_1k_flights,
    ROUND(100.0 * c.spread, 1)                                     AS pct_spread,
    ROUND(c.mult, 2)                                               AS avg_multiplier,
    ROUND(c.cost / 1e6, 1)                                         AS chain_cost_million,
    ROUND(c.cost / f.flights, 0)                                   AS chain_cost_per_flight
FROM f
JOIN c USING (airline);

-- 5. Top 30 airports
DROP TABLE IF EXISTS dashboard.airports;
CREATE TABLE dashboard.airports AS
WITH d AS (
    SELECT origin,
           MAX(origin_city)                                        AS city,
           MAX(origin_state)                                       AS state,
           COUNT(*) FILTER (WHERE NOT is_cancelled)                AS departures
    FROM analytics.flights
    GROUP BY origin
)
SELECT
    c.start_airport                                                AS airport,
    d.city,
    d.state,
    d.departures,
    COUNT(*)                                                       AS chains,
    ROUND(1000.0 * COUNT(*) / d.departures, 1)                     AS chains_per_1k_departures,
    ROUND(100.0 * AVG((c.downstream_flights > 0)::int), 1)         AS pct_spread,
    ROUND(SUM(c.total_cost_usd) / 1e6, 1)                          AS chain_cost_million,
    ROUND(SUM(c.total_delay_min - c.starter_delay_min) * 98.41 / 1e6, 1) AS downstream_cost_million
FROM analytics.delay_chains c
JOIN d ON d.origin = c.start_airport
GROUP BY c.start_airport, d.city, d.state, d.departures
ORDER BY chain_cost_million DESC
LIMIT 30;

-- 6. Chains by time of day
DROP TABLE IF EXISTS dashboard.time_of_day;
CREATE TABLE dashboard.time_of_day AS
SELECT
    start_time_of_day                                              AS time_of_day,
    COUNT(*)                                                       AS chains,
    ROUND(100.0 * AVG((downstream_flights > 0)::int), 1)           AS pct_spread,
    ROUND(AVG(delay_multiplier), 2)                                AS avg_multiplier,
    ROUND(AVG(total_cost_usd), 0)                                  AS avg_chain_cost,
    ROUND(SUM(total_cost_usd) / 1e9, 2)                            AS chain_cost_billion
FROM analytics.delay_chains
GROUP BY start_time_of_day
ORDER BY 1;

-- 7. Top 25 hotspots (airport x time of day)
DROP TABLE IF EXISTS dashboard.hotspots;
CREATE TABLE dashboard.hotspots AS
SELECT
    start_airport || ' ' || SUBSTRING(start_time_of_day FROM 4)    AS hotspot,
    start_airport                                                  AS airport,
    start_time_of_day                                              AS time_of_day,
    COUNT(*)                                                       AS chains,
    ROUND(100.0 * AVG((downstream_flights > 0)::int), 1)           AS pct_spread,
    ROUND(AVG(delay_multiplier), 2)                                AS avg_multiplier,
    ROUND(SUM(total_delay_min - starter_delay_min) * 98.41 / 1e6, 1) AS downstream_cost_million
FROM analytics.delay_chains
GROUP BY start_airport, start_time_of_day
ORDER BY downstream_cost_million DESC
LIMIT 25;

-- 8. AA @ DFW: turnaround time vs delay passed on
DROP TABLE IF EXISTS dashboard.turn_buckets;
CREATE TABLE dashboard.turn_buckets AS
SELECT
    turn_bucket,
    COUNT(*)                                                       AS late_arrivals,
    ROUND(100.0 * AVG((dep_delay_minutes >= 15)::int), 1)          AS pct_passed_on,
    ROUND(AVG(incoming_delay_min - dep_delay_minutes)::numeric, 1) AS avg_minutes_absorbed
FROM analytics.linked_legs
WHERE airline = 'AA' AND origin = 'DFW' AND incoming_delay_min >= 15
GROUP BY turn_bucket
ORDER BY turn_bucket;

-- 9. Hub benchmark
DROP TABLE IF EXISTS dashboard.hub_benchmark;
CREATE TABLE dashboard.hub_benchmark AS
SELECT
    CASE airline WHEN 'AA' THEN 'American' WHEN 'DL' THEN 'Delta'
                 WHEN 'UA' THEN 'United'   WHEN 'WN' THEN 'Southwest' END
        || ' @ ' || origin                                         AS hub,
    COUNT(*)                                                       AS turns,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP
          (ORDER BY sched_turn_min::float8)::numeric, 0)           AS median_turn_min,
    ROUND(100.0 * AVG((sched_turn_min < 45)::int), 1)              AS pct_turns_under_45,
    ROUND(100.0 * AVG((dep_delay_minutes >= 15)::int)
          FILTER (WHERE incoming_delay_min >= 15), 1)              AS pct_passed_on_when_late
FROM analytics.linked_legs
WHERE (airline, origin) IN (('AA','DFW'), ('AA','CLT'), ('DL','ATL'),
                            ('UA','ORD'), ('UA','DEN'), ('WN','DEN'))
GROUP BY airline, origin;

-- 10. Risk tiers: does 2024 risk predict 2025 lateness?
DROP TABLE IF EXISTS dashboard.risk_tiers;
CREATE TABLE dashboard.risk_tiers AS
SELECT
    CASE
        WHEN r.late_rate_2024 IS NULL  THEN '0. No 2024 history'
        WHEN r.late_rate_2024 < 0.15   THEN '1. Under 15%'
        WHEN r.late_rate_2024 < 0.20   THEN '2. 15-20%'
        WHEN r.late_rate_2024 < 0.25   THEN '3. 20-25%'
        WHEN r.late_rate_2024 < 0.30   THEN '4. 25-30%'
        WHEN r.late_rate_2024 < 0.35   THEN '5. 30-35%'
        ELSE                                '6. 35%+'
    END                                                            AS risk_tier_2024,
    COUNT(*)                                                       AS turns_2025,
    ROUND(100.0 * AVG((a.incoming_delay_min >= 15)::int), 1)       AS pct_inbound_late_2025
FROM analytics.aa_dfw_turns a
LEFT JOIN analytics.aa_dfw_inbound_risk r USING (inbound_from, inbound_arr_hour)
WHERE a.year = 2025
GROUP BY 1
ORDER BY 1;

-- 11. Buffer strategies: blanket vs risk-based (2025, target 75 min)
DROP TABLE IF EXISTS dashboard.buffer_strategies;
CREATE TABLE dashboard.buffer_strategies AS
WITH t AS (
    SELECT a.*, COALESCE(r.late_rate_2024, 0) AS risk
    FROM analytics.aa_dfw_turns a
    LEFT JOIN analytics.aa_dfw_inbound_risk r USING (inbound_from, inbound_arr_hour)
    WHERE a.year = 2025 AND a.sched_turn_min < 75
),
th(threshold, label) AS (VALUES
    (0.00, '1. Blanket (all turns)'), (0.15, '2. Inbound late 15%+'),
    (0.20, '3. Inbound late 20%+'),   (0.25, '4. Inbound late 25%+'),
    (0.30, '5. Inbound late 30%+'),   (0.35, '6. Inbound late 35%+'),
    (0.40, '7. Inbound late 40%+')),
calc AS (
    SELECT th.label,
           COUNT(t.sched_turn_min)                                 AS turns_buffered,
           SUM(75 - t.sched_turn_min)                              AS buffer_min,
           SUM(CASE WHEN t.incoming_delay_min >= 15
                    THEN LEAST(0.57 * (75 - t.sched_turn_min), t.dep_delay_minutes)
                    ELSE 0 END)                                    AS saved_min
    FROM th
    LEFT JOIN t ON t.risk >= th.threshold
    GROUP BY th.label
)
SELECT
    label                                                          AS strategy,
    turns_buffered,
    ROUND(buffer_min::numeric, 0)                                  AS buffer_min,
    ROUND(saved_min::numeric, 0)                                   AS delay_min_saved,
    ROUND((saved_min * 98.41 / NULLIF(buffer_min, 0))::numeric, 2) AS breakeven_per_min,
    ROUND(((saved_min * 98.41 - buffer_min * 24.60) / 1e6)::numeric, 2) AS net_million_at_24_60
FROM calc
ORDER BY label;

-- Quick check
SELECT * FROM dashboard.headline;