-- ============================================================
-- Lesson 05: factory database schema (MySQL 8)
-- Run: mysql -u root -p < sql/01_schema.sql
-- ============================================================
DROP DATABASE IF EXISTS factory;
CREATE DATABASE factory CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE factory;

-- Production lines (parent table)
CREATE TABLE line (
    line_id SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,  -- surrogate key
    code VARCHAR(20) NOT NULL,
    name VARCHAR(100) NOT NULL,
    CONSTRAINT uq_line_code UNIQUE (code)  -- natural key stays unique
) ENGINE = InnoDB;

-- Machines belong to a line (one-to-many)
CREATE TABLE machine (
    machine_id SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    line_id SMALLINT UNSIGNED NOT NULL,
    code VARCHAR(20) NOT NULL,
    name VARCHAR(100) NOT NULL,
    ideal_cycle_s DECIMAL(6,2) NOT NULL,  -- seconds per part at 100 % speed
    plc_ip VARCHAR(45) NULL,  -- 45 chars fits IPv6
    active BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT uq_machine_code UNIQUE (code),
    CONSTRAINT fk_machine_line FOREIGN KEY (line_id) REFERENCES line (line_id)
        ON UPDATE CASCADE ON DELETE RESTRICT  -- can't delete a line that has machines
) ENGINE = InnoDB;

-- Shift calendar (C shift crosses midnight)
CREATE TABLE shift (
    shift_code CHAR(1) PRIMARY KEY,  -- natural key: 'A', 'B', 'C'
    start_time TIME NOT NULL,
    end_time TIME NOT NULL
) ENGINE = InnoDB;

-- One row per finished part (the big, fast-growing table)
CREATE TABLE production (
    production_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    machine_id SMALLINT UNSIGNED NOT NULL,
    ts DATETIME(3) NOT NULL,  -- millisecond timestamp
    part_qr VARCHAR(40) NOT NULL,
    result ENUM('OK','NG') NOT NULL,
    cycle_time_s DECIMAL(6,2) NOT NULL,
    CONSTRAINT uq_production_qr UNIQUE (part_qr),  -- each QR produced once
    CONSTRAINT fk_production_machine FOREIGN KEY (machine_id) REFERENCES machine (machine_id),
    CONSTRAINT chk_cycle_positive CHECK (cycle_time_s > 0),
    INDEX ix_production_machine_ts (machine_id, ts),  -- "machine X between time A and B"
    INDEX ix_production_ts (ts)  -- "all machines between A and B"
) ENGINE = InnoDB;

-- Alarm catalogue (lookup table)
CREATE TABLE alarm_def (
    alarm_code SMALLINT UNSIGNED PRIMARY KEY,
    text VARCHAR(200) NOT NULL,
    severity ENUM('INFO','WARNING','FAULT') NOT NULL
) ENGINE = InnoDB;

-- Every alarm occurrence; end_ts NULL = still active
CREATE TABLE alarm_history (
    alarm_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    machine_id SMALLINT UNSIGNED NOT NULL,
    alarm_code SMALLINT UNSIGNED NOT NULL,
    start_ts DATETIME NOT NULL,
    end_ts DATETIME NULL,
    ack_by VARCHAR(50) NULL,
    CONSTRAINT fk_alarm_machine FOREIGN KEY (machine_id) REFERENCES machine (machine_id),
    CONSTRAINT fk_alarm_def FOREIGN KEY (alarm_code) REFERENCES alarm_def (alarm_code),
    CONSTRAINT chk_alarm_order CHECK (end_ts IS NULL OR end_ts >= start_ts),
    INDEX ix_alarm_machine_start (machine_id, start_ts),
    INDEX ix_alarm_active (end_ts)  -- fast "WHERE end_ts IS NULL"
) ENGINE = InnoDB;
