-- 02_indexes_and_checks.sql
-- Run AFTER load_to_postgres.py finishes.

-- ---------- Indexes ----------
-- Key index for delay-chain tracing: follow each aircraft through its day
CREATE INDEX IF NOT EXISTS idx_tail_day
    ON raw.flights (tail_number, flight_date, crs_dep_time);

CREATE INDEX IF NOT EXISTS idx_flight_date ON raw.flights (flight_date);
CREATE INDEX IF NOT EXISTS idx_airline     ON raw.flights (airline);
CREATE INDEX IF NOT EXISTS idx_origin      ON raw.flights (origin);
CREATE INDEX IF NOT EXISTS idx_dest        ON raw.flights (dest);

ANALYZE raw.flights;

-- ---------- Validation checks ----------
-- 1. Total rows (expect roughly 30M+)
SELECT COUNT(*) AS total_rows FROM raw.flights;

-- 2. Rows per year
SELECT year, COUNT(*) AS flights
FROM raw.flights
GROUP BY year
ORDER BY year;

-- 3. All 60 months present?
SELECT COUNT(DISTINCT (year, month)) AS months_loaded FROM raw.flights;

-- 4. Missing tail numbers (should be a small %)
SELECT ROUND(100.0 * AVG((tail_number IS NULL)::int), 2) AS pct_missing_tail
FROM raw.flights;

-- 5. On-time performance and cancellation rate by year
SELECT year,
       ROUND((100.0 * (1 - AVG(arr_del15)))::numeric, 1) AS otp_pct,
       ROUND((100.0 * AVG(cancelled))::numeric, 2)       AS cancel_pct
FROM raw.flights
GROUP BY year
ORDER BY year;