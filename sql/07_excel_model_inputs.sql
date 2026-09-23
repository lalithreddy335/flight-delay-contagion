-- 07_excel_model_inputs.sql
-- Inputs for the Excel buffer savings model: AA @ DFW turnarounds, 2025.

-- A. Summary (sanity check)
SELECT
    time_of_day,
    COUNT(*)                                                      AS turns,
    SUM((sched_turn_min < 75)::int)                               AS turns_under_75,
    ROUND(AVG(75 - sched_turn_min)
          FILTER (WHERE sched_turn_min < 75)::numeric, 1)         AS avg_shortfall_min,
    SUM((sched_turn_min < 75 AND incoming_delay_min >= 15)::int)  AS short_and_late
FROM analytics.linked_legs
WHERE airline = 'AA' AND origin = 'DFW' AND year = 2025
GROUP BY time_of_day
ORDER BY time_of_day;

-- B. Flight-level data for Excel (export this one to CSV)
SELECT
    time_of_day,
    dep_hour,
    ROUND(sched_turn_min::numeric, 0)   AS sched_turn_min,
    incoming_delay_min,
    dep_delay_minutes
FROM analytics.linked_legs
WHERE airline = 'AA' AND origin = 'DFW' AND year = 2025
ORDER BY dep_hour;