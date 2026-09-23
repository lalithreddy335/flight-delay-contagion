-- 05_chain_hotspots.sql
-- Where do costly delay chains start? Airports, airlines, airport x time.
-- Downstream cost = cost of delays AFTER the starter flight
-- (the money a buffer could save by stopping the spread).

-- ---------- Q1. Top 15 airports by chain cost ----------
WITH deps AS (
    SELECT origin, COUNT(*) AS departures
    FROM analytics.flights
    WHERE NOT is_cancelled
    GROUP BY origin
)
SELECT
    c.start_airport                                                  AS airport,
    d.departures,
    COUNT(*)                                                         AS chains,
    ROUND(1000.0 * COUNT(*) / d.departures, 1)                       AS chains_per_1k_departures,
    ROUND(100.0 * AVG((c.downstream_flights > 0)::int), 1)           AS pct_spread,
    ROUND(AVG(c.delay_multiplier), 2)                                AS avg_multiplier,
    ROUND(SUM(c.total_cost_usd) / 1e6, 1)                            AS chain_cost_million,
    ROUND(SUM(c.total_delay_min - c.starter_delay_min) * 98.41 / 1e6, 1)
                                                                     AS downstream_cost_million,
    ROUND(100.0 * SUM(c.total_cost_usd) / SUM(SUM(c.total_cost_usd)) OVER (), 1)
                                                                     AS pct_of_all_chain_cost
FROM analytics.delay_chains c
JOIN deps d ON d.origin = c.start_airport
GROUP BY c.start_airport, d.departures
ORDER BY chain_cost_million DESC
LIMIT 15;

-- ---------- Q2. Airlines ----------
WITH flights_by_airline AS (
    SELECT airline, COUNT(*) AS flights
    FROM analytics.flights
    WHERE NOT is_cancelled
    GROUP BY airline
)
SELECT
    c.start_airline                                                  AS code,
    CASE c.start_airline
        WHEN 'AA' THEN 'American'   WHEN 'DL' THEN 'Delta'
        WHEN 'UA' THEN 'United'     WHEN 'WN' THEN 'Southwest'
        WHEN 'AS' THEN 'Alaska'     WHEN 'B6' THEN 'JetBlue'
        WHEN 'NK' THEN 'Spirit'     WHEN 'F9' THEN 'Frontier'
        WHEN 'G4' THEN 'Allegiant'  WHEN 'HA' THEN 'Hawaiian'
        WHEN 'OO' THEN 'SkyWest'    WHEN 'YX' THEN 'Republic'
        WHEN 'MQ' THEN 'Envoy'      WHEN '9E' THEN 'Endeavor'
        WHEN 'OH' THEN 'PSA'        WHEN 'YV' THEN 'Mesa'
        WHEN 'QX' THEN 'Horizon'    WHEN 'ZW' THEN 'Air Wisconsin'
        WHEN 'C5' THEN 'CommuteAir' WHEN 'PT' THEN 'Piedmont'
        WHEN 'G7' THEN 'GoJet'      WHEN 'EV' THEN 'ExpressJet'
        ELSE c.start_airline
    END                                                              AS airline_name,
    f.flights,
    COUNT(*)                                                         AS chains,
    ROUND(1000.0 * COUNT(*) / f.flights, 1)                          AS chains_per_1k_flights,
    ROUND(100.0 * AVG((c.downstream_flights > 0)::int), 1)           AS pct_spread,
    ROUND(AVG(c.delay_multiplier), 2)                                AS avg_multiplier,
    ROUND(SUM(c.total_cost_usd) / 1e6, 1)                            AS chain_cost_million,
    ROUND(SUM(c.total_cost_usd) / f.flights, 0)                      AS chain_cost_per_flight_usd
FROM analytics.delay_chains c
JOIN flights_by_airline f ON f.airline = c.start_airline
GROUP BY c.start_airline, f.flights
ORDER BY chain_cost_million DESC;

-- ---------- Q3. Top 20 airport x time-of-day hotspots (the buffer targets) ----------
SELECT
    start_airport                                                    AS airport,
    start_time_of_day,
    COUNT(*)                                                         AS chains,
    ROUND(100.0 * AVG((downstream_flights > 0)::int), 1)             AS pct_spread,
    ROUND(AVG(delay_multiplier), 2)                                  AS avg_multiplier,
    ROUND(SUM(total_delay_min - starter_delay_min) * 98.41 / 1e6, 1) AS downstream_cost_million
FROM analytics.delay_chains
GROUP BY start_airport, start_time_of_day
ORDER BY downstream_cost_million DESC
LIMIT 20;