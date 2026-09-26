# Lesson 06 — SQL Queries: Joins, GROUP BY, Time Buckets

All queries: [`sql/03_queries.sql`](../sql/03_queries.sql). Run them one at a time in
Workbench (`Ctrl+Enter`) after loading the schema and seed data from Lesson 05.

## 1. Order of a SELECT

Written:   `SELECT → FROM → JOIN → WHERE → GROUP BY → HAVING → ORDER BY → LIMIT`
Executed:  `FROM/JOIN → WHERE → GROUP BY → HAVING → SELECT → ORDER BY → LIMIT`

This explains the classic confusion: **WHERE filters rows before grouping; HAVING filters
groups after.**

## 2. Joins

```
INNER JOIN  → only matching rows             ( A ∩ B )
LEFT JOIN   → all of A, B where it matches   ( A, NULLs where B missing )
```

```sql
-- INNER: parts with their machine and line names
SELECT p.part_qr, m.code, l.name
FROM production p
JOIN machine m ON m.machine_id = p.machine_id
JOIN line    l ON l.line_id    = m.line_id;

-- LEFT: every machine, even with 0 parts (M4 appears with 0)
SELECT m.code, COUNT(p.production_id) AS parts
FROM machine m
LEFT JOIN production p ON p.machine_id = m.machine_id
GROUP BY m.code;
```

Key details:
- Use table aliases (`p`, `m`) and always qualify columns.
- With LEFT JOIN, count a column from the right table (`COUNT(p.production_id)`), not `COUNT(*)`,
  or a machine with no parts counts as 1.
- `LEFT JOIN … WHERE right.id IS NULL` = "find what's missing".
- A filter on the right table of a LEFT JOIN belongs in `ON`, not `WHERE`, or it silently
  turns into an INNER JOIN.

## 3. GROUP BY + aggregates

`COUNT`, `SUM`, `AVG`, `MIN`, `MAX`. Every non-aggregated column in SELECT must be in GROUP BY.

```sql
SELECT m.code,
       COUNT(*)                                        AS total,
       SUM(p.result = 'OK')                            AS ok,       -- TRUE = 1 in MySQL
       ROUND(100 * SUM(p.result = 'OK') / COUNT(*), 1) AS yield_pct
FROM production p
JOIN machine m ON m.machine_id = p.machine_id
GROUP BY m.code;

-- HAVING: only machines with more than 15 NG parts
SELECT machine_id, COUNT(*) AS ng_parts
FROM production WHERE result = 'NG'
GROUP BY machine_id
HAVING COUNT(*) > 15;
```

Durations: `TIMESTAMPDIFF(MINUTE, start_ts, COALESCE(end_ts, NOW()))`, where `COALESCE`
handles still-active alarms (`end_ts IS NULL`).

## 4. Time buckets: the heart of every production dashboard

**Hourly:** format the timestamp down to the hour and group by it.

```sql
SELECT DATE_FORMAT(ts, '%Y-%m-%d %H:00') AS hour_bucket, COUNT(*) AS parts
FROM production
GROUP BY hour_bucket;
```

**Any size (5/15/30 min):** round the Unix time down.

```sql
FROM_UNIXTIME(FLOOR(UNIX_TIMESTAMP(ts) / 900) * 900)     -- 900 s = 15 min
```

**Shifts:** the hard part is the C shift (22:00–06:00) crossing midnight.
Parts made at 02:00 on the 26th belong to the **25th's** C shift. Trick: shift the clock
back by the first shift's start time.

```sql
SELECT DATE(ts - INTERVAL 6 HOUR) AS prod_date,
       CASE
           WHEN TIME(ts) >= '06:00' AND TIME(ts) < '14:00' THEN 'A'
           WHEN TIME(ts) >= '14:00' AND TIME(ts) < '22:00' THEN 'B'
           ELSE 'C'
       END AS shift_code,
       COUNT(*) AS parts
FROM production
GROUP BY prod_date, shift_code;
```

Better for clients: **join the `shift` table** so shift times are data, not code (method 2 in
the script). It handles the midnight case with
`start_time > end_time AND (TIME(ts) >= start_time OR TIME(ts) < end_time)`.

**Missing buckets:** GROUP BY can't show hours with zero parts; they simply don't exist.
Generate every hour with a recursive CTE, then LEFT JOIN production onto it (see script:
M2's breakdown at 14:00–16:00 shows as 0 instead of vanishing from the chart).

## 5. Bonus: window functions

Calculations across rows **without** collapsing them like GROUP BY does:

```sql
SUM(parts) OVER (ORDER BY hour_bucket)          -- running total
parts - LAG(parts) OVER (ORDER BY hour_bucket)  -- change vs previous hour
RANK() OVER (PARTITION BY line ORDER BY parts DESC)  -- ranking inside each group
```

## 6. OEE from SQL

- **Availability** = run time / planned time (from `alarm_history` downtime)
- **Performance** = `COUNT(*) * ideal_cycle_s / SUM(cycle_time_s)`
- **Quality** = OK / total

All three are queries in this lesson. In Phase 1.3 they become the dashboard.
