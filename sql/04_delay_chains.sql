-- 04_delay_chains.sql
-- Traces delay propagation aircraft-by-aircraft.
-- Late      = arrived 15+ min late (DOT standard)
-- Linked    = same tail, previous leg landed where this leg departs,
--             scheduled turnaround 0-6 hours
-- Inherited = linked AND previous leg late AND this leg departed 15+ min late
-- Starter   = late leg that did NOT inherit its delay (a chain begins here)

-- ================= PART A: late legs with chain IDs =================
DROP TABLE IF EXISTS analytics.late_legs;

CREATE TABLE analytics.late_legs AS
WITH ops AS (
    SELECT
        tail_number, flight_date, year, month, airline,
        origin, dest, route, dep_hour, time_of_day,
        sched_dep_ts, sched_arr_ts,
        dep_delay_minutes, arr_delay_minutes, delay_cost_usd,
        carrier_delay, weather_delay, nas_delay, security_delay, late_aircraft_delay,
        LAG(dest)              OVER w AS prev_dest,
        LAG(sched_arr_ts)      OVER w AS prev_sched_arr_ts,
        LAG(arr_delay_minutes) OVER w AS prev_arr_delay
    FROM analytics.flights
    WHERE NOT is_cancelled
      AND NOT is_diverted
      AND tail_number IS NOT NULL
    WINDOW w AS (PARTITION BY tail_number ORDER BY sched_dep_ts)
),
flagged AS (
    SELECT
        *,
        EXTRACT(EPOCH FROM (sched_dep_ts - prev_sched_arr_ts)) / 60 AS sched_turn_min,
        COALESCE(
            prev_dest = origin
            AND sched_dep_ts - prev_sched_arr_ts BETWEEN INTERVAL '0 minutes' AND INTERVAL '6 hours',
            FALSE)                                                    AS is_linked
    FROM ops
),
classified AS (
    SELECT
        *,
        (is_linked AND prev_arr_delay >= 15 AND dep_delay_minutes >= 15) AS is_inherited
    FROM flagged
    WHERE arr_delay_minutes >= 15          -- keep only late legs
)
SELECT
    *,
    SUM(CASE WHEN is_inherited THEN 0 ELSE 1 END)
        OVER (PARTITION BY tail_number ORDER BY sched_dep_ts) AS chain_seq
FROM classified;

CREATE INDEX idx_ll_chain ON analytics.late_legs (tail_number, chain_seq);
ANALYZE analytics.late_legs;

-- ================= PART B: one row per delay chain =================
DROP TABLE IF EXISTS analytics.delay_chains;

CREATE TABLE analytics.delay_chains AS
SELECT
    tail_number,
    chain_seq,
    MIN(sched_dep_ts)                                        AS chain_start_ts,
    (ARRAY_AGG(year        ORDER BY sched_dep_ts))[1]        AS start_year,
    (ARRAY_AGG(airline     ORDER BY sched_dep_ts))[1]        AS start_airline,
    (ARRAY_AGG(origin      ORDER BY sched_dep_ts))[1]        AS start_airport,
    (ARRAY_AGG(dep_hour    ORDER BY sched_dep_ts))[1]        AS start_dep_hour,
    (ARRAY_AGG(time_of_day ORDER BY sched_dep_ts))[1]        AS start_time_of_day,
    (ARRAY_AGG(arr_delay_minutes ORDER BY sched_dep_ts))[1]::numeric AS starter_delay_min,
    COUNT(*)                                                 AS chain_length,
    COUNT(*) - 1                                             AS downstream_flights,
    SUM(arr_delay_minutes)::numeric                          AS total_delay_min,
    SUM(delay_cost_usd)                                      AS total_cost_usd
FROM analytics.late_legs
GROUP BY tail_number, chain_seq;

ALTER TABLE analytics.delay_chains ADD COLUMN delay_multiplier NUMERIC;
UPDATE analytics.delay_chains
SET delay_multiplier = total_delay_min / NULLIF(starter_delay_min, 0);

ANALYZE analytics.delay_chains;

-- ================= PART C: first results =================
-- C1. The big picture
SELECT
    COUNT(*)                                                     AS total_chains,
    ROUND(AVG(chain_length), 2)                                  AS avg_chain_length,
    ROUND(100.0 * AVG((downstream_flights > 0)::int), 1)         AS pct_chains_that_spread,
    MAX(chain_length)                                            AS longest_chain,
    ROUND(100.0 * SUM(total_delay_min - starter_delay_min)
                / SUM(total_delay_min), 1)                       AS pct_delay_minutes_inherited,
    ROUND(SUM(total_cost_usd) / 1e9, 2)                          AS chain_cost_billion_usd
FROM analytics.delay_chains;

-- C2. Does WHEN a delay starts change how far it spreads?
SELECT
    start_time_of_day,
    COUNT(*)                                                     AS chains,
    ROUND(100.0 * AVG((downstream_flights > 0)::int), 1)         AS pct_spread,
    ROUND(AVG(downstream_flights), 2)                            AS avg_downstream_flights,
    ROUND(AVG(delay_multiplier), 2)                              AS avg_multiplier,
    ROUND(AVG(total_cost_usd), 0)                                AS avg_chain_cost_usd
FROM analytics.delay_chains
GROUP BY start_time_of_day
ORDER BY start_time_of_day;

-- C3. Sanity check vs BTS's own cause codes
SELECT ROUND((100.0 * SUM(late_aircraft_delay)
       / NULLIF(SUM(carrier_delay + weather_delay + nas_delay
                    + security_delay + late_aircraft_delay), 0))::numeric, 1)
       AS bts_late_aircraft_pct
FROM analytics.flights;