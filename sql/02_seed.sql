-- ============================================================
-- Sample data: 2 lines, 4 machines, 3 shifts, 1 day of parts + alarms
-- Run after 01_schema.sql:  mysql -u root -p factory < sql/02_seed.sql
-- ============================================================
USE factory;

INSERT INTO line (code, name) VALUES
    ('L1', 'Assembly Line 1'),
    ('L2', 'Machining Line 2');

INSERT INTO machine (line_id, code, name, ideal_cycle_s, plc_ip) VALUES
    (1, 'M1', 'Press',        60.00, '192.168.0.11'),
    (1, 'M2', 'Welder',       90.00, '192.168.0.12'),
    (2, 'M3', 'CNC Lathe',   120.00, '192.168.0.21'),
    (2, 'M4', 'Test Bench',   45.00, NULL);          -- M4 produces nothing (LEFT JOIN demo)

INSERT INTO shift VALUES
    ('A', '06:00:00', '14:00:00'),
    ('B', '14:00:00', '22:00:00'),
    ('C', '22:00:00', '06:00:00');                   -- crosses midnight

-- Generate one part every ~2 minutes for 24 h (720 slots) on M1..M3.
-- A recursive CTE creates the numbers 0..719.
SET SESSION cte_max_recursion_depth = 1000;

INSERT INTO production (machine_id, ts, part_qr, result, cycle_time_s)
WITH RECURSIVE n (i) AS (
    SELECT 0
    UNION ALL
    SELECT i + 1 FROM n WHERE i < 719
)
SELECT m.machine_id,
       TIMESTAMP('2026-09-25 06:00:00') + INTERVAL (n.i * 120 + m.machine_id * 7) SECOND,
       CONCAT('QR-', m.code, '-', LPAD(n.i, 5, '0')),
       IF(RAND(n.i * 10 + m.machine_id) < 0.03, 'NG', 'OK'),       -- ~3 % scrap
       ROUND(m.ideal_cycle_s * (1 + RAND(n.i + m.machine_id) * 0.25), 2)
FROM n
JOIN machine m ON m.code IN ('M1', 'M2', 'M3')
WHERE NOT (m.code = 'M2' AND n.i BETWEEN 240 AND 299);             -- M2 down 2 h in shift B

INSERT INTO alarm_def VALUES
    (101, 'Emergency stop pressed',   'FAULT'),
    (204, 'Material shortage',        'WARNING'),
    (305, 'Door open',                'WARNING'),
    (410, 'Spindle overheat',         'FAULT');

INSERT INTO alarm_history (machine_id, alarm_code, start_ts, end_ts, ack_by) VALUES
    (1, 204, '2026-09-25 07:15:00', '2026-09-25 07:32:00', 'ravi'),
    (1, 305, '2026-09-25 11:02:00', '2026-09-25 11:05:30', 'ravi'),
    (2, 101, '2026-09-25 14:00:00', '2026-09-25 16:00:00', 'kumar'),
    (3, 410, '2026-09-25 23:40:00', '2026-09-26 00:25:00', 'selvi'),
    (3, 204, '2026-09-26 03:10:00', '2026-09-26 03:18:00', 'selvi'),
    (1, 305, '2026-09-26 05:50:00', NULL, NULL);                    -- still active
