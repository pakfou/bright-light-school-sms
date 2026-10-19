USE bls_school_db;
SET FOREIGN_KEY_CHECKS = 0;

-- =============================================
-- 1. FIX attendance table columns
-- =============================================

-- Make student_id nullable (server inserts NULL for teacher attendance)
ALTER TABLE attendance MODIFY student_id INT NULL;

-- Make classroom_id nullable (teacher attendance has no classroom)
ALTER TABLE attendance MODIFY classroom_id INT NULL;

-- Drop scanned_by if it exists (server.js doesn't use it)
SET @has_col = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = 'bls_school_db' AND TABLE_NAME = 'attendance' AND COLUMN_NAME = 'scanned_by');
SET @sql = IF(@has_col > 0, 'ALTER TABLE attendance DROP COLUMN scanned_by', 'SELECT 1');
PREPARE st FROM @sql; EXECUTE st; DEALLOCATE PREPARE st;

-- =============================================
-- 2. FIX schedules FK: teacher_id -> teachers(id) instead of users(id)
-- =============================================
SET @fk_ref = (SELECT REFERENCED_TABLE_NAME FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE 
    WHERE TABLE_SCHEMA = 'bls_school_db' AND TABLE_NAME = 'schedules' 
    AND COLUMN_NAME = 'teacher_id' AND REFERENCED_TABLE_NAME IS NOT NULL LIMIT 1);

SET @fk_name = (SELECT CONSTRAINT_NAME FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE 
    WHERE TABLE_SCHEMA = 'bls_school_db' AND TABLE_NAME = 'schedules' 
    AND COLUMN_NAME = 'teacher_id' AND REFERENCED_TABLE_NAME IS NOT NULL LIMIT 1);

-- Only fix if FK points to 'users' instead of 'teachers'
SET @sql = IF(@fk_ref = 'users', 
    CONCAT('ALTER TABLE schedules DROP FOREIGN KEY ', @fk_name, 
           ', ADD CONSTRAINT fk_sched_teacher FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE CASCADE'), 
    'SELECT 1');
PREPARE st FROM @sql; EXECUTE st; DEALLOCATE PREPARE st;

-- =============================================
-- 3. FIX teacher_salaries FK: teacher_id -> teachers(id) instead of users(id)
-- =============================================
SET @fk_ref2 = (SELECT REFERENCED_TABLE_NAME FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE 
    WHERE TABLE_SCHEMA = 'bls_school_db' AND TABLE_NAME = 'teacher_salaries' 
    AND COLUMN_NAME = 'teacher_id' AND REFERENCED_TABLE_NAME IS NOT NULL LIMIT 1);

SET @fk_name2 = (SELECT CONSTRAINT_NAME FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE 
    WHERE TABLE_SCHEMA = 'bls_school_db' AND TABLE_NAME = 'teacher_salaries' 
    AND COLUMN_NAME = 'teacher_id' AND REFERENCED_TABLE_NAME IS NOT NULL LIMIT 1);

SET @sql = IF(@fk_ref2 = 'users', 
    CONCAT('ALTER TABLE teacher_salaries DROP FOREIGN KEY ', @fk_name2, 
           ', ADD CONSTRAINT fk_sal_teacher FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE CASCADE'), 
    'SELECT 1');
PREPARE st FROM @sql; EXECUTE st; DEALLOCATE PREPARE st;

SET FOREIGN_KEY_CHECKS = 1;

SELECT 'All column and FK fixes applied!' AS result;
