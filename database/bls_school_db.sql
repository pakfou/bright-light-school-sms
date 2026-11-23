-- ==============================================================================
-- 🏫 BRIGHT LIGHT INTERNATIONAL SCHOOL (BLS) - PRODUCTION DATABASE SCHEMA
-- Compatible with TiDB Cloud MySQL, MySQL 8.0, and MariaDB
-- Character Set: utf8mb4 (Full Khmer & International Unicode Support)
-- ==============================================================================

CREATE DATABASE IF NOT EXISTS bls_school_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE bls_school_db;

-- ------------------------------------------------------------------------------
-- ១. ROLES & USERS (Role-Based Access Control)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(100) UNIQUE NOT NULL,
    name VARCHAR(150) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL DEFAULT 'Admin',
    role_type VARCHAR(50) DEFAULT 'Admin',
    phone VARCHAR(50) NULL,
    telegram_chat_id VARCHAR(100) NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'Active',
    last_login TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_user_role (role),
    INDEX idx_user_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------------------------
-- ២. GRADE LEVELS & CLASSROOMS (Academic Hierarchy)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS grade_levels (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    study_type VARCHAR(50) NOT NULL DEFAULT 'Full-Time',
    monthly_fee DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    description TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS classrooms (
    id INT AUTO_INCREMENT PRIMARY KEY,
    grade_level_id INT NULL,
    class_name VARCHAR(100) NOT NULL,
    level_type VARCHAR(50) NULL DEFAULT 'Full-Time',
    study_type VARCHAR(50) NULL DEFAULT 'Full-Time',
    shift VARCHAR(50) DEFAULT 'Morning',
    room_number VARCHAR(50) DEFAULT 'Room-01',
    capacity INT DEFAULT 30,
    teacher_name VARCHAR(150) NULL DEFAULT '',
    academic_year VARCHAR(50) NOT NULL DEFAULT '2025-2026',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_cls_grade (grade_level_id),
    INDEX idx_cls_shift (shift)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------------------------
-- ៣. TEACHERS & STAFF (គ្រូបង្រៀន និងបុគ្គលិក)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS teachers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NULL,
    teacher_code VARCHAR(50) UNIQUE NOT NULL,
    name_kh VARCHAR(150) NOT NULL,
    name_en VARCHAR(150) NULL,
    gender VARCHAR(20) DEFAULT 'Male',
    dob DATE NULL,
    phone VARCHAR(50) NULL,
    email VARCHAR(150) NULL,
    role_title VARCHAR(100) DEFAULT 'គ្រូបង្រៀន',
    specialized_subject VARCHAR(150) NULL,
    degree VARCHAR(150) NULL,
    employment_type VARCHAR(50) DEFAULT 'Full-Time',
    base_salary DECIMAL(10,2) DEFAULT 0.00,
    status VARCHAR(50) NOT NULL DEFAULT 'Active',
    hire_date DATE NULL,
    photo_url LONGTEXT NULL,
    telegram_chat_id VARCHAR(100) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_tch_code (teacher_code),
    INDEX idx_tch_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------------------------
-- ៤. STUDENTS & GUARDIANS (សិស្ស និងអាណាព្យាបាល)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS students (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NULL,
    student_code VARCHAR(50) UNIQUE NOT NULL,
    name_kh VARCHAR(150) NOT NULL,
    name_en VARCHAR(150) NULL,
    gender VARCHAR(20) DEFAULT 'Female',
    dob DATE NULL,
    pob VARCHAR(255) NULL,
    current_address TEXT NULL,
    parent_name VARCHAR(150) NULL,
    parent_relation VARCHAR(50) DEFAULT 'Father',
    parent_occupation VARCHAR(100) NULL,
    parent_phone VARCHAR(50) NULL,
    parent_phone_2 VARCHAR(50) NULL,
    emergency_phone VARCHAR(50) NULL,
    telegram_chat_id VARCHAR(100) NULL,
    study_type VARCHAR(50) NOT NULL DEFAULT 'Full-Time',
    shift VARCHAR(50) DEFAULT 'Morning',
    part_time_course VARCHAR(50) DEFAULT 'None',
    classroom_id INT NULL,
    photo_url LONGTEXT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'Active',
    allergies_notes TEXT NULL,
    health_notes TEXT NULL,
    special_notes TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_std_code (student_code),
    INDEX idx_std_class (classroom_id),
    INDEX idx_std_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------------------------
-- ៥. ATTENDANCE (ប្រព័ន្ធកត់ត្រាវត្តមាន)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS attendance (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NULL,
    teacher_id INT NULL,
    classroom_id INT NULL,
    date DATE NOT NULL,
    shift VARCHAR(50) DEFAULT 'Morning',
    status VARCHAR(50) NOT NULL DEFAULT 'Present',
    method VARCHAR(50) DEFAULT 'QR_Scan',
    note VARCHAR(255) NULL,
    scanned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_att_date (date),
    INDEX idx_att_student (student_id),
    INDEX idx_att_teacher (teacher_id),
    INDEX idx_att_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------------------------
-- ៦. SCHEDULES & TIMETABLE (កាលវិភាគ)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS schedules (
    id INT AUTO_INCREMENT PRIMARY KEY,
    classroom_id INT NULL,
    teacher_id INT NULL,
    subject_name VARCHAR(150) NOT NULL,
    subject VARCHAR(150) NULL,
    day_of_week VARCHAR(20) NOT NULL DEFAULT 'Mon',
    start_time VARCHAR(20) NOT NULL DEFAULT '07:30',
    end_time VARCHAR(20) NOT NULL DEFAULT '09:00',
    shift VARCHAR(20) NOT NULL DEFAULT 'Morning',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_sched_class (classroom_id),
    INDEX idx_sched_teacher (teacher_id),
    INDEX idx_sched_day (day_of_week)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------------------------
-- ៧. GRADES & SCORES (ពិន្ទុ មធ្យមភាគ និងចំណាត់ថ្នាក់)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS student_grades (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    classroom_id INT NULL,
    subject_name VARCHAR(150) NOT NULL,
    month_name VARCHAR(50) DEFAULT 'ប្រចាំខែ',
    attendance_score DECIMAL(5,2) DEFAULT 10.00,
    homework_score DECIMAL(5,2) DEFAULT 30.00,
    exam_score DECIMAL(5,2) DEFAULT 60.00,
    score DECIMAL(5,2) NOT NULL DEFAULT 0.00,
    grade_letter VARCHAR(5) DEFAULT 'C',
    rank_in_class INT NULL,
    remarks TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_grd_student (student_id),
    INDEX idx_grd_class (classroom_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------------------------
-- ៨. INVOICES & PAYMENTS (ការទូទាត់ និងវិក្កយបត្រ)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS invoices (
    id INT AUTO_INCREMENT PRIMARY KEY,
    invoice_no VARCHAR(50) UNIQUE NOT NULL,
    student_id INT NOT NULL,
    billing_month VARCHAR(50) NOT NULL,
    original_amount DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    discount_type VARCHAR(20) DEFAULT 'None',
    discount_val DECIMAL(10,2) DEFAULT 0.00,
    net_amount DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    due_date DATE NULL,
    status VARCHAR(30) DEFAULT 'Pending',
    slip_image_url LONGTEXT NULL,
    khqr_payload TEXT NULL,
    approved_by VARCHAR(150) NULL,
    approved_at TIMESTAMP NULL,
    verified_by INT NULL,
    verified_at DATETIME NULL,
    rejection_reason VARCHAR(255) NULL,
    receipt_number VARCHAR(50) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_inv_student (student_id),
    INDEX idx_inv_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS student_payments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    invoice_no VARCHAR(50) NULL,
    student_id INT NOT NULL,
    invoice_id INT NULL,
    amount DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    paid_date DATE NULL,
    payment_date DATE NULL,
    payment_method VARCHAR(50) DEFAULT 'KHQR',
    transaction_ref VARCHAR(100) NULL,
    received_by VARCHAR(100) NULL,
    note VARCHAR(255) NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'Paid',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_pmt_student (student_id),
    INDEX idx_pmt_date (paid_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS teacher_salaries (
    id INT AUTO_INCREMENT PRIMARY KEY,
    pay_slip_no VARCHAR(50) NULL,
    teacher_id INT NOT NULL,
    salary_month VARCHAR(50) NULL,
    base_salary DECIMAL(10,2) DEFAULT 0.00,
    bonus DECIMAL(10,2) DEFAULT 0.00,
    deductions DECIMAL(10,2) DEFAULT 0.00,
    net_salary DECIMAL(10,2) NULL,
    paid_date DATE NULL,
    status VARCHAR(50) DEFAULT 'Paid',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_sal_teacher (teacher_id),
    INDEX idx_sal_date (paid_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------------------------
-- ៩. AUDIT LOGS & CLOSINGS
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS audit_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NULL,
    user_name VARCHAR(150) NULL,
    role VARCHAR(50) NULL,
    action VARCHAR(100) NOT NULL,
    table_name VARCHAR(100) NOT NULL,
    record_id INT NULL,
    old_values JSON NULL,
    new_values JSON NULL,
    ip_address VARCHAR(50) NULL,
    user_agent TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_audit_table (table_name),
    INDEX idx_audit_time (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS period_closings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    closing_type VARCHAR(50) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    total_income DECIMAL(10,2) DEFAULT 0.00,
    total_expense DECIMAL(10,2) DEFAULT 0.00,
    net_profit DECIMAL(10,2) DEFAULT 0.00,
    closed_by VARCHAR(150) NULL,
    notes TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------------------------
-- ១០. DEFAULT SEED DATA
-- ------------------------------------------------------------------------------
INSERT INTO users (username, name, email, password, role, status)
VALUES ('admin', 'អ្នកគ្រប់គ្រងប្រព័ន្ធ', 'admin@brightlight.edu.kh', '$2a$10$wT3Wq7m3Zz1N2jR9Y5mY9OCW7S9g9Z3XgO4f1mC8sY8Z9K1M1m1m.', 'Admin', 'Active')
ON DUPLICATE KEY UPDATE password = '$2a$10$wT3Wq7m3Zz1N2jR9Y5mY9OCW7S9g9Z3XgO4f1mC8sY8Z9K1M1m1m.';

INSERT INTO teachers (teacher_code, name_kh, name_en, gender, role_title, specialized_subject, base_salary, status)
VALUES ('TCH-TEST', 'គ្រូបង្រៀន សាកល្បង', 'Test Teacher', 'Male', 'គ្រូបង្រៀន', 'ចំណេះដឹងទូទៅ', 450.00, 'Active')
ON DUPLICATE KEY UPDATE name_kh = 'គ្រូបង្រៀន សាកល្បង';
