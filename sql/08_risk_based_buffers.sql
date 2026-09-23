-- 08_risk_based_buffers.sql
-- Risk-based buffering: buffer only turns whose inbound flight is chronically late.
-- Risk is learned from 2024 and tested on 2025 (out-of-sample, no hindsight).
-- Inbound flight "identity" = origin airport + scheduled arrival hour at DFW.

-- ================= PART A: AA turns at DFW with inbound details =================
DROP TABLE IF EXISTS analytics.aa_dfw_turns;

CREATE TABLE analytics.aa_dfw_turns AS
WITH ops AS (
    SELECT
        year, tail_number, origin, dest, time_of_day,
        sched_dep_ts, sched_arr_ts, dep_delay_minutes, arr_delay_minutes,
        LAG(origin)            OVER w AS prev_origin,
        LAG(dest)              OVER w AS prev_dest,
        LAG(sched_arr_ts)      OVER w AS prev_sched_arr_ts,
        LAG(arr_delay_minutes) OVER w AS prev_arr_delay
    FROM analytics.flights
    WHERE airline = 'AA'
      AND NOT is_cancelled AND NOT is_diverted
      AND tail_number IS NOT NULL
      AND year IN (2024, 2025)
    WINDOW w AS (PARTITION BY tail_number ORDER BY sched_dep_ts)
)
SELECT
    year,
    time_of_day,
    prev_origin                                                        AS inbound_from,
    EXTRACT(HOUR FROM prev_sched_arr_ts)::int                          AS inbound_arr_hour,
    (EXTRACT(EPOCH FROM (sched_dep_ts - prev_sched_arr_ts)) / 60)::real AS sched_turn_min,
    prev_arr_delay                                                     AS incoming_delay_min,
    dep_delay_minutes
FROM ops
WHERE origin = 'DFW'
  AND prev_dest = 'DFW'
  AND sched_dep_ts - prev_sched_arr_ts BETWEEN INTERVAL '0 minutes' AND INTERVAL '6 hours';

-- ================= PART B: 2024 late rate for each inbound flight =================
DROP TABLE IF EXISTS analytics.aa_dfw_inbound_risk;

CREATE TABLE analytics.aa_dfw_inbound_risk AS
SELECT
    origin                                        AS inbound_from,
    EXTRACT(HOUR FROM sched_arr_ts)::int          AS inbound_arr_hour,
    COUNT(*)                                      AS flights_2024,
    AVG((arr_delay_minutes >= 15)::int)           AS late_rate_2024
FROM analytics.flights
WHERE airline = 'AA'
  AND dest = 'DFW'
  AND year = 2024
  AND NOT is_cancelled AND NOT is_diverted
GROUP BY origin, EXTRACT(HOUR FROM sched_arr_ts)
HAVING COUNT(*) >= 30;          -- only flights with enough history

-- ================= PART C: results =================

-- C1. Does 2024 risk predict 2025 lateness? (validation)
SELECT
    CASE
        WHEN r.late_rate_2024 IS NULL  THEN '0. No 2024 history'
        WHEN r.late_rate_2024 < 0.15   THEN '1. Under 15%'
        WHEN r.late_rate_2024 < 0.20   THEN '2. 15-20%'
        WHEN r.late_rate_2024 < 0.25   THEN '3. 20-25%'
        WHEN r.late_rate_2024 < 0.30   THEN '4. 25-30%'
        WHEN r.late_rate_2024 < 0.35   THEN '5. 30-35%'
        ELSE                                '6. 35%+'
    END                                                        AS risk_tier_2024,
    COUNT(*)                                                   AS turns_2025,
    ROUND(100.0 * AVG((a.incoming_delay_min >= 15)::int), 1)   AS pct_inbound_late_2025
FROM analytics.aa_dfw_turns a
LEFT JOIN analytics.aa_dfw_inbound_risk r USING (inbound_from, inbound_arr_hour)
WHERE a.year = 2025
GROUP BY 1
ORDER BY 1;

-- C2. Buffer only turns (under 75 min) whose inbound 2024 late rate >= threshold
--     Target 75 min, absorption 0.57, $98.41/delay min, $24.60/ground min
WITH t AS (
    SELECT a.*, COALESCE(r.late_rate_2024, 0) AS risk
    FROM analytics.aa_dfw_turns a
    LEFT JOIN analytics.aa_dfw_inbound_risk r USING (inbound_from, inbound_arr_hour)
    WHERE a.year = 2025
      AND a.sched_turn_min < 75
),
th(threshold) AS (VALUES (0.00), (0.15), (0.20), (0.25), (0.30), (0.35), (0.40)),
calc AS (
    SELECT
        th.threshold,
        COUNT(t.sched_turn_min)                                          AS turns_buffered,
        AVG((t.incoming_delay_min >= 15)::int)                           AS late_share,
        SUM(75 - t.sched_turn_min)                                       AS buffer_min,
        SUM(CASE WHEN t.incoming_delay_min >= 15
                 THEN LEAST(0.57 * (75 - t.sched_turn_min), t.dep_delay_minutes)
                 ELSE 0 END)                                             AS saved_min
    FROM th
    LEFT JOIN t ON t.risk >= th.threshold
    GROUP BY th.threshold
)
SELECT
    threshold                                                   AS min_inbound_late_rate,
    turns_buffered,
    ROUND(100.0 * late_share, 1)                                AS pct_inbound_late_2025,
    ROUND(buffer_min::numeric, 0)                               AS buffer_min,
    ROUND(saved_min::numeric, 0)                                AS delay_min_saved,
    ROUND((saved_min * 98.41 / NULLIF(buffer_min, 0))::numeric, 2) AS breakeven_per_min,
    ROUND((saved_min * 98.41 - buffer_min * 24.60)::numeric, 0) AS net_at_24_60
FROM calc
ORDER BY threshold;