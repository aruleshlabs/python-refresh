# Lesson 05 — SQL on MySQL: Schema Design, Keys, Indexes

Scripts: [`sql/01_schema.sql`](../sql/01_schema.sql) (tables) and [`sql/02_seed.sql`](../sql/02_seed.sql) (one day of sample factory data).

```powershell
mysql -u root -p < sql/01_schema.sql
mysql -u root -p factory < sql/02_seed.sql
```

(Or open them in MySQL Workbench and press the ⚡ button.)

## 1. Schema design: think in entities

List the *things* in the plant and how they relate, then make **one table per thing**:

```text
line 1───* machine 1───* production        (one line has many machines, …)
                   1───* alarm_history *───1 alarm_def
shift  (calendar, used for reports)
```

**Normalization, in one sentence:** store each fact in exactly one place. Machine name lives in `machine`, not repeated in 1 million `production` rows; production just stores `machine_id`. Rename a machine once and every report is correct.

Exception: dashboards sometimes keep **summary tables** (e.g. `hourly_production`) on purpose for speed. That is fine as long as the raw table stays the source of truth.

## 2. Data types: pick the smallest correct one

| Data | Type | Why |
|---|---|---|
| IDs of small tables | `SMALLINT UNSIGNED` (0–65535) | Machines/lines will never reach 65k |
| IDs of big tables | `BIGINT UNSIGNED` | Production rows grow forever |
| Timestamps | `DATETIME(3)` | Millisecond precision; no 2038 limit like `TIMESTAMP` |
| Money/measurements | `DECIMAL(6,2)` | Exact; `FLOAT` gives 0.1 + 0.2 ≠ 0.3 |
| Fixed choices | `ENUM('OK','NG')` | 1 byte, rejects invalid values |
| Text | `VARCHAR(n)` | Sized to real max |
| Flags | `BOOLEAN` | Stored as `TINYINT(1)` |

Always use `utf8mb4` (full Unicode) and `ENGINE = InnoDB` (transactions + foreign keys).

## 3. Keys = rules the database enforces for you

| Key | Meaning | Example |
|---|---|---|
| `PRIMARY KEY` | Unique + `NOT NULL` row identity; one per table | `production_id` |
| Surrogate key | Meaningless auto number | `machine_id AUTO_INCREMENT` |
| Natural key | Real-world identifier | `machine.code = 'M1'`, `shift_code = 'A'` |
| `UNIQUE` | No duplicates (`NULL` allowed) | `part_qr`: a QR can't be produced twice |
| `FOREIGN KEY` | Value must exist in the parent table | `production.machine_id → machine` |
| `CHECK` | Custom rule (MySQL 8.0.16+) | `cycle_time_s > 0` |

Use a surrogate PK **and** a `UNIQUE` natural key (see `machine`): joins stay fast and small, and duplicates are still impossible.

Foreign key actions:

- `ON DELETE RESTRICT` (default): refuses to delete a line that still has machines. **Safest.**
- `ON DELETE CASCADE`: deletes children too. Use rarely; never on production history.
- `ON UPDATE CASCADE`: if the parent key changes, children follow.

Constraints are your last line of defence: even if your Python code has a bug, the database refuses bad data.

## 4. Indexes = the book's index

Without an index MySQL reads **every row** (full table scan). With one, it jumps straight to the rows. `PRIMARY KEY` and `UNIQUE` columns are indexed automatically.

```sql
INDEX ix_production_machine_ts (machine_id, ts)
```

**Composite index rule: leftmost prefix.** `(machine_id, ts)` helps:

| Query filter | Uses index? |
|---|---|
| `machine_id = 1` | ✅ |
| `machine_id = 1 AND ts BETWEEN …` | ✅ best case: equality first, range last |
| `ts BETWEEN …` only | ❌ that's why there's also `ix_production_ts (ts)` |

**Don't break your index** by wrapping the column in a function:

```sql
WHERE DATE(ts) = '2026-09-25'  -- ❌ scans every row
WHERE ts >= '2026-09-25' AND ts < '2026-09-26'  -- ✅ uses index
```

**Check with `EXPLAIN`:**

```sql
EXPLAIN SELECT COUNT(*) FROM production
WHERE machine_id = 1 AND ts >= '2026-09-25 14:00' AND ts < '2026-09-25 22:00';
```

Look at `key` (which index) and `rows` (how many rows it will read). `type = ALL` means full scan.

- **What to index:** columns in `WHERE`, `JOIN ... ON`, and `ORDER BY` of frequent queries.
- **What not to index:** every column. Each index slows down every `INSERT` and uses disk. For a PLC logger inserting thousands of rows per minute, 2–3 well-chosen indexes beat 10 random ones.

## 5. Commands you'll use

```sql
SHOW DATABASES; USE factory;
SHOW TABLES; DESCRIBE production;
SHOW CREATE TABLE production\G
SHOW INDEX FROM production;
ALTER TABLE machine ADD COLUMN vendor VARCHAR(50) NULL;
ALTER TABLE production ADD INDEX ix_result (result);
DROP INDEX ix_result ON production;
```

Install (Windows): *MySQL Installer* → MySQL Server 8.0 + MySQL Workbench (free, Community edition).
