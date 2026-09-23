-- 06_turnaround_analysis.sql
-- Does scheduled turnaround time absorb incoming delays?
-- Focus: American (AA) at DFW, benchmarked vs Delta, United, Southwest hubs.

-- ================= PART A: linked legs for the big 4 airlines =================
DROP TABLE IF EXISTS analytics.linked_legs;

CREATE TABLE analytics.linked_legs AS
WITH ops AS (
    SELECT
        airline, tail_number, year, origin, dep_hour, time_of_day, sched_dep_ts,
        dep_delay_minutes, arr_delay_minutes,
        LAG(dest)              OVER w AS prev_dest,
        LAG(sched_arr_ts)      OVER w AS prev_sched_arr_ts,
        LAG(arr_delay_minutes) OVER w AS prev_arr_delay
    FROM analytics.flights
    WHERE NOT is_cancelled
      AND NOT is_diverted
      AND tail_number IS NOT NULL
      AND airline IN ('AA', 'DL', 'UA', 'WN')
    WINDOW w AS (PARTITION BY tail_number ORDER BY sched_dep_ts)
),
linked AS (
    SELECT
        airline, tail_number, year, origin, dep_hour, time_of_day,
        (EXTRACT(EPOCH FROM (sched_dep_ts - prev_sched_arr_ts)) / 60)::real AS sched_turn_min,
        prev_arr_delay      AS incoming_delay_min,
        dep_delay_minutes,
        arr_delay_minutes
    FROM ops
    WHERE prev_dest = origin
      AND sched_dep_ts - prev_sched_arr_ts BETWEEN INTERVAL '0 minutes' AND INTERVAL '6 hours'
)
SELECT
    *,
    CASE
        WHEN sched_turn_min < 40  THEN '1. Under 40 min'
        WHEN sched_turn_min < 50  THEN '2. 40-49 min'
        WHEN sched_turn_min < 60  THEN '3. 50-59 min'
        WHEN sched_turn_min < 75  THEN '4. 60-74 min'
        WHEN sched_turn_min < 90  THEN '5. 75-89 min'
        WHEN sched_turn_min < 120 THEN '6. 90-119 min'
        ELSE                           '7. 120+ min'
    END AS turn_bucket
FROM linked;

CREATE INDEX idx_ll2_airline_origin ON analytics.linked_legs (airline, origin);
ANALYZE analytics.linked_legs;

-- ================= PART B: results =================

-- B1. AA at DFW: when the incoming plane is 15+ min late,
--     does more turnaround time stop the delay from passing on?
SELECT
    turn_bucket,
    COUNT(*)                                                     AS late_arrivals,
    ROUND(AVG(incoming_delay_min)::numeric, 1)                   AS avg_incoming_delay,
    ROUND(100.0 * AVG((dep_delay_minutes >= 15)::int), 1)        AS pct_delay_passed_on,
    ROUND(AVG(dep_delay_minutes)::numeric, 1)                    AS avg_dep_delay,
    ROUND(AVG(incoming_delay_min - dep_delay_minutes)::numeric, 1) AS avg_minutes_absorbed
FROM analytics.linked_legs
WHERE airline = 'AA'
  AND origin = 'DFW'
  AND incoming_delay_min >= 15
GROUP BY turn_bucket
ORDER BY turn_bucket;

-- B2. Benchmark: how tight are turnarounds at each airline's main hubs?
SELECT
    airline || ' @ ' || origin                                   AS hub,
    COUNT(*)                                                     AS turns,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP
          (ORDER BY sched_turn_min::float8)::numeric, 0)         AS median_turn_min,
    ROUND(100.0 * AVG((sched_turn_min < 45)::int), 1)            AS pct_turns_under_45,
    ROUND(100.0 * AVG((dep_delay_minutes >= 15)::int)
          FILTER (WHERE incoming_delay_min >= 15), 1)            AS pct_passed_on_when_late
FROM analytics.linked_legs
WHERE (airline, origin) IN (('AA','DFW'), ('AA','CLT'), ('DL','ATL'),
                            ('UA','ORD'), ('UA','DEN'), ('WN','DEN'))
GROUP BY airline, origin
ORDER BY median_turn_min;

-- B3. AA at DFW by time of day
SELECT
    time_of_day,
    COUNT(*)                                                     AS turns,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP
          (ORDER BY sched_turn_min::float8)::numeric, 0)         AS median_turn_min,
    ROUND(100.0 * AVG((sched_turn_min < 45)::int), 1)            AS pct_turns_under_45,
    ROUND(100.0 * AVG((incoming_delay_min >= 15)::int), 1)       AS pct_arrive_late,
    ROUND(100.0 * AVG((dep_delay_minutes >= 15)::int)
          FILTER (WHERE incoming_delay_min >= 15), 1)            AS pct_passed_on_when_late
FROM analytics.linked_legs
WHERE airline = 'AA'
  AND origin = 'DFW'
GROUP BY time_of_day
ORDER BY time_of_day;