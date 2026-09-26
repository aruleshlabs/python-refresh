-- ============================================================
-- Lesson 06: joins, GROUP BY, time buckets (hourly / shift)
-- Run the statements one by one in MySQL Workbench (Ctrl+Enter).
-- ============================================================
USE factory;

-- ---------- 1. Basics ----------
SELECT code, name, ideal_cycle_s FROM machine WHERE active ORDER BY code;

-- Index-friendly date filter: a range on the raw column, NOT DATE(ts) = ...
SELECT COUNT(*) FROM production
WHERE ts >= '2026-09-25 06:00:00' AND ts < '2026-09-26 06:00:00';

-- ---------- 2. JOINS ----------
-- INNER JOIN: only rows that match on both sides
SELECT p.part_qr, p.ts, m.code AS machine, l.name AS line
FROM production p
JOIN machine m ON m.machine_id = p.machine_id
JOIN line    l ON l.line_id    = m.line_id
ORDER BY p.ts
LIMIT 10;

-- LEFT JOIN: keep ALL machines, even with zero production (M4 shows 0)
SELECT m.code, COUNT(p.production_id) AS parts
FROM machine m
LEFT JOIN production p ON p.machine_id = m.machine_id
GROUP BY m.code
ORDER BY m.code;

-- LEFT JOIN + IS NULL: "find what is missing" (machines that never produced)
SELECT m.code
FROM machine m
LEFT JOIN production p ON p.machine_id = m.machine_id
WHERE p.production_id IS NULL;

-- Active alarms with their text (join to lookup table)
SELECT m.code, a.alarm_code, d.text, d.severity, a.start_ts,
       TIMESTAMPDIFF(MINUTE, a.start_ts, NOW()) AS minutes_active
FROM alarm_history a
JOIN machine   m ON m.machine_id = a.machine_id
JOIN alarm_def d ON d.alarm_code = a.alarm_code
WHERE a.end_ts IS NULL;

-- ---------- 3. GROUP BY + aggregates ----------
-- Count, OK/NG split and yield per machine
SELECT m.code,
       COUNT(*)                               AS total,
       SUM(p.result = 'OK')                   AS ok,        -- TRUE counts as 1
       SUM(p.result = 'NG')                   AS ng,
       ROUND(100 * SUM(p.result = 'OK') / COUNT(*), 1) AS yield_pct,
       ROUND(AVG(p.cycle_time_s), 1)          AS avg_cycle_s
FROM production p
JOIN machine m ON m.machine_id = p.machine_id
GROUP BY m.code;

-- HAVING filters AFTER grouping (WHERE filters BEFORE)
SELECT machine_id, COUNT(*) AS ng_parts
FROM production
WHERE result = 'NG'
GROUP BY machine_id
HAVING COUNT(*) > 15;

-- Top alarms by total downtime
SELECT d.text,
       COUNT(*) AS occurrences,
       SUM(TIMESTAMPDIFF(MINUTE, a.start_ts, COALESCE(a.end_ts, NOW()))) AS total_min
FROM alarm_history a
JOIN alarm_def d ON d.alarm_code = a.alarm_code
GROUP BY d.text
ORDER BY total_min DESC;

-- ---------- 4. TIME BUCKETS ----------
-- Hourly production per machine
SELECT DATE_FORMAT(p.ts, '%Y-%m-%d %H:00') AS hour_bucket,
       m.code,
       COUNT(*) AS parts
FROM production p
JOIN machine m ON m.machine_id = p.machine_id
GROUP BY hour_bucket, m.code
ORDER BY hour_bucket, m.code;

-- Any bucket size: 15-minute buckets via Unix time
SELECT FROM_UNIXTIME(FLOOR(UNIX_TIMESTAMP(ts) / 900) * 900) AS bucket_15m,
       COUNT(*) AS parts
FROM production
WHERE machine_id = 1
GROUP BY bucket_15m
ORDER BY bucket_15m;

-- Shift report (method 1: CASE).
-- Production date trick: subtract 6 h so 00:00-05:59 belongs to the previous day's C shift.
SELECT DATE(p.ts - INTERVAL 6 HOUR) AS prod_date,
       CASE
           WHEN TIME(p.ts) >= '06:00' AND TIME(p.ts) < '14:00' THEN 'A'
           WHEN TIME(p.ts) >= '14:00' AND TIME(p.ts) < '22:00' THEN 'B'
           ELSE 'C'
       END AS shift_code,
       COUNT(*) AS parts,
       SUM(p.result = 'NG') AS ng
FROM production p
GROUP BY prod_date, shift_code
ORDER BY prod_date, shift_code;

-- Shift report (method 2: JOIN the shift table, so times are configurable, not hard-coded)
SELECT DATE(p.ts - INTERVAL 6 HOUR) AS prod_date,
       s.shift_code,
       m.code,
       COUNT(*) AS parts
FROM production p
JOIN machine m ON m.machine_id = p.machine_id
JOIN shift s ON (
       (s.start_time < s.end_time AND TIME(p.ts) >= s.start_time AND TIME(p.ts) < s.end_time)
    OR (s.start_time > s.end_time AND (TIME(p.ts) >= s.start_time OR TIME(p.ts) < s.end_time))
)
GROUP BY prod_date, s.shift_code, m.code
ORDER BY prod_date, s.shift_code, m.code;

-- Hours with ZERO production still appear (generate all 24 hours, then LEFT JOIN).
-- M2 was down 14:00-16:00; those hours show 0 instead of disappearing.
WITH RECURSIVE hours (h) AS (
    SELECT TIMESTAMP('2026-09-25 06:00:00')
    UNION ALL
    SELECT h + INTERVAL 1 HOUR FROM hours WHERE h < '2026-09-26 05:00:00'
)
SELECT hours.h AS hour_start, COUNT(p.production_id) AS parts
FROM hours
LEFT JOIN production p
       ON p.machine_id = 2
      AND p.ts >= hours.h AND p.ts < hours.h + INTERVAL 1 HOUR
GROUP BY hours.h
ORDER BY hours.h;

-- ---------- 5. Window functions (bonus) ----------
-- Running total per shift day and change vs previous hour
WITH hourly AS (
    SELECT DATE_FORMAT(ts, '%Y-%m-%d %H:00') AS hour_bucket, COUNT(*) AS parts
    FROM production
    GROUP BY hour_bucket
)
SELECT hour_bucket,
       parts,
       SUM(parts) OVER (ORDER BY hour_bucket)         AS running_total,
       parts - LAG(parts) OVER (ORDER BY hour_bucket) AS change_vs_prev
FROM hourly
ORDER BY hour_bucket;

-- Performance of each machine: ideal time / actual time (OEE "P" factor)
SELECT m.code,
       ROUND(100 * COUNT(*) * m.ideal_cycle_s / SUM(p.cycle_time_s), 1) AS performance_pct
FROM production p
JOIN machine m ON m.machine_id = p.machine_id
GROUP BY m.code, m.ideal_cycle_s;

-- ---------- 6. Check your indexes are used ----------
EXPLAIN SELECT COUNT(*) FROM production
WHERE machine_id = 1 AND ts >= '2026-09-25 14:00' AND ts < '2026-09-25 22:00';
-- Look for key = ix_production_machine_ts and a small "rows" estimate.
