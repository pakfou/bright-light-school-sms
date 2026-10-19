-- ============================================================
-- Fix 500 errors: ensure DB matches server.js expectations
-- Compatible with MySQL versions without IF NOT EXISTS for columns
-- ============================================================
USE bls_school_db;

-- ──────────────────────────────────────────
-- 1. grade_levels table (server.js uses this)
-- ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS grade_levels (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    study_type ENUM('Full-Time', 'Part-Time') NOT NULL DEFAULT 'Full-Time',
    description TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ──────────────────────────────────────────
-- 2. Ensure teachers table exists
-- ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS teachers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NULL,
    teacher_code VARCHAR(50) UNIQUE NOT NULL,
    name_kh VARCHAR(150) NOT NULL,
    name_en VARCHAR(150) NULL,
    gender VARCHAR(10) DEFAULT 'Male',
    dob DATE NULL,
    phone VARCHAR(50) NULL,
    email VARCHAR(150) NULL,
    role_title VARCHAR(100) DEFAULT 'គ្រូបង្រៀន',
    specialized_subject VARCHAR(150) NULL,
    base_salary DECIMAL(10,2) DEFAULT 0.00,
    status VARCHAR(20) DEFAULT 'Active',
    hire_date DATE NULL,
    photo_url VARCHAR(255) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- ──────────────────────────────────────────
-- 3. Unified attendance table 
-- ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS attendance (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NULL,
    teacher_id INT NULL,
    classroom_id INT NULL,
    date DATE NOT NULL,
    shift ENUM('Morning', 'Afternoon') DEFAULT 'Morning',
    status ENUM('Present', 'Absent', 'Permission', 'Late') DEFAULT 'Present',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ──────────────────────────────────────────
-- 4. Ensure schedules table has subject_name & shift columns
-- ──────────────────────────────────────────
-- Drop and recreate if the old schema is totally different
-- First, let's just try creating if not exists
SET @has_subject_name = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = 'bls_school_db' AND TABLE_NAME = 'schedules' AND COLUMN_NAME = 'subject_name');

SET @sql1 = IF(@has_subject_name = 0, 
    'ALTER TABLE schedules ADD COLUMN subject_name VARCHAR(100) NULL', 'SELECT 1');
PREPARE stmt1 FROM @sql1; EXECUTE stmt1; DEALLOCATE PREPARE stmt1;

SET @has_shift = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = 'bls_school_db' AND TABLE_NAME = 'schedules' AND COLUMN_NAME = 'shift');

SET @sql2 = IF(@has_shift = 0, 
    "ALTER TABLE schedules ADD COLUMN shift ENUM('Morning', 'Afternoon') DEFAULT 'Morning'", 'SELECT 1');
PREPARE stmt2 FROM @sql2; EXECUTE stmt2; DEALLOCATE PREPARE stmt2;

-- ──────────────────────────────────────────
-- 5. Add missing columns to classrooms
-- ──────────────────────────────────────────
SET @has_glid = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = 'bls_school_db' AND TABLE_NAME = 'classrooms' AND COLUMN_NAME = 'grade_level_id');

SET @sql3 = IF(@has_glid = 0, 
    'ALTER TABLE classrooms ADD COLUMN grade_level_id INT NULL', 'SELECT 1');
PREPARE stmt3 FROM @sql3; EXECUTE stmt3; DEALLOCATE PREPARE stmt3;

SET @has_cap = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = 'bls_school_db' AND TABLE_NAME = 'classrooms' AND COLUMN_NAME = 'capacity');

SET @sql4 = IF(@has_cap = 0, 
    'ALTER TABLE classrooms ADD COLUMN capacity INT DEFAULT 30', 'SELECT 1');
PREPARE stmt4 FROM @sql4; EXECUTE stmt4; DEALLOCATE PREPARE stmt4;

-- ──────────────────────────────────────────
-- 6. Add missing columns to students
-- ──────────────────────────────────────────
SET @v = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = 'bls_school_db' AND TABLE_NAME = 'students' AND COLUMN_NAME = 'part_time_course');
SET @s = IF(@v = 0, "ALTER TABLE students ADD COLUMN part_time_course VARCHAR(50) DEFAULT 'None'", 'SELECT 1');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @v = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = 'bls_school_db' AND TABLE_NAME = 'students' AND COLUMN_NAME = 'photo_url');
SET @s = IF(@v = 0, 'ALTER TABLE students ADD COLUMN photo_url VARCHAR(255) NULL', 'SELECT 1');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @v = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = 'bls_school_db' AND TABLE_NAME = 'students' AND COLUMN_NAME = 'status');
SET @s = IF(@v = 0, "ALTER TABLE students ADD COLUMN status VARCHAR(20) DEFAULT 'Active'", 'SELECT 1');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

-- ──────────────────────────────────────────
-- 7. Add missing columns to attendance
-- ──────────────────────────────────────────
SET @v = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = 'bls_school_db' AND TABLE_NAME = 'attendance' AND COLUMN_NAME = 'teacher_id');
SET @s = IF(@v = 0, 'ALTER TABLE attendance ADD COLUMN teacher_id INT NULL', 'SELECT 1');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @v = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = 'bls_school_db' AND TABLE_NAME = 'attendance' AND COLUMN_NAME = 'shift');
SET @s = IF(@v = 0, "ALTER TABLE attendance ADD COLUMN shift ENUM('Morning', 'Afternoon') DEFAULT 'Morning'", 'SELECT 1');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @v = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = 'bls_school_db' AND TABLE_NAME = 'attendance' AND COLUMN_NAME = 'created_at');
SET @s = IF(@v = 0, 'ALTER TABLE attendance ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP', 'SELECT 1');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

-- ──────────────────────────────────────────
-- 8. Fix student_grades columns
-- ──────────────────────────────────────────
SET @v = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = 'bls_school_db' AND TABLE_NAME = 'student_grades' AND COLUMN_NAME = 'subject_name');
SET @s = IF(@v = 0, 'ALTER TABLE student_grades ADD COLUMN subject_name VARCHAR(100) NULL', 'SELECT 1');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @v = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = 'bls_school_db' AND TABLE_NAME = 'student_grades' AND COLUMN_NAME = 'month_name');
SET @s = IF(@v = 0, 'ALTER TABLE student_grades ADD COLUMN month_name VARCHAR(50) NULL', 'SELECT 1');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @v = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = 'bls_school_db' AND TABLE_NAME = 'student_grades' AND COLUMN_NAME = 'remarks');
SET @s = IF(@v = 0, 'ALTER TABLE student_grades ADD COLUMN remarks TEXT NULL', 'SELECT 1');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

-- ──────────────────────────────────────────
-- 9. Fix student_payments columns
-- ──────────────────────────────────────────
SET @v = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = 'bls_school_db' AND TABLE_NAME = 'student_payments' AND COLUMN_NAME = 'invoice_no');
SET @s = IF(@v = 0, 'ALTER TABLE student_payments ADD COLUMN invoice_no VARCHAR(50) NULL', 'SELECT 1');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @v = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = 'bls_school_db' AND TABLE_NAME = 'student_payments' AND COLUMN_NAME = 'payment_method');
SET @s = IF(@v = 0, "ALTER TABLE student_payments ADD COLUMN payment_method VARCHAR(50) DEFAULT 'KHQR'", 'SELECT 1');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @v = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = 'bls_school_db' AND TABLE_NAME = 'student_payments' AND COLUMN_NAME = 'note');
SET @s = IF(@v = 0, 'ALTER TABLE student_payments ADD COLUMN note VARCHAR(255) NULL', 'SELECT 1');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @v = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = 'bls_school_db' AND TABLE_NAME = 'student_payments' AND COLUMN_NAME = 'paid_date');
SET @s = IF(@v = 0, 'ALTER TABLE student_payments ADD COLUMN paid_date DATE NULL', 'SELECT 1');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

-- ──────────────────────────────────────────
-- 10. Fix teacher_salaries columns
-- ──────────────────────────────────────────
SET @v = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = 'bls_school_db' AND TABLE_NAME = 'teacher_salaries' AND COLUMN_NAME = 'pay_slip_no');
SET @s = IF(@v = 0, 'ALTER TABLE teacher_salaries ADD COLUMN pay_slip_no VARCHAR(50) NULL', 'SELECT 1');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @v = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = 'bls_school_db' AND TABLE_NAME = 'teacher_salaries' AND COLUMN_NAME = 'salary_month');
SET @s = IF(@v = 0, 'ALTER TABLE teacher_salaries ADD COLUMN salary_month VARCHAR(50) NULL', 'SELECT 1');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @v = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = 'bls_school_db' AND TABLE_NAME = 'teacher_salaries' AND COLUMN_NAME = 'deductions');
SET @s = IF(@v = 0, 'ALTER TABLE teacher_salaries ADD COLUMN deductions DECIMAL(10,2) DEFAULT 0.00', 'SELECT 1');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @v = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = 'bls_school_db' AND TABLE_NAME = 'teacher_salaries' AND COLUMN_NAME = 'net_salary');
SET @s = IF(@v = 0, 'ALTER TABLE teacher_salaries ADD COLUMN net_salary DECIMAL(10,2) NULL', 'SELECT 1');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @v = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = 'bls_school_db' AND TABLE_NAME = 'teacher_salaries' AND COLUMN_NAME = 'paid_date');
SET @s = IF(@v = 0, 'ALTER TABLE teacher_salaries ADD COLUMN paid_date DATE NULL', 'SELECT 1');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SELECT 'All fixes applied successfully!' AS result;
