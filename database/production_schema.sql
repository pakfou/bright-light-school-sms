-- ==============================================================================
-- 🏫 BRIGHT LIGHT INTERNATIONAL SCHOOL (BLS) - PRODUCTION DATABASE SCHEMA
-- Version: 3.0 (Production-Ready Normalized Relational Schema)
-- Character Set: utf8mb4 (Full Khmer & International Unicode Support)
-- ==============================================================================

CREATE DATABASE IF NOT EXISTS bls_school_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE bls_school_db;

-- ------------------------------------------------------------------------------
-- ១. ROLES & USERS (Role-Based Access Control - RBAC)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(100) UNIQUE NOT NULL,
    name VARCHAR(150) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL, -- bcrypt hashed
    role ENUM('Admin', 'Teacher', 'Accountant', 'Parent', 'Student') NOT NULL DEFAULT 'Admin',
    phone VARCHAR(50) NULL,
    telegram_chat_id VARCHAR(100) NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
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
    name VARCHAR(100) NOT NULL, -- ឧ. មត្តេយ្យ, បឋមសិក្សា, ថ្នាក់ទី១ - ទី១២
    study_type ENUM('Full-Time', 'Part-Time') NOT NULL DEFAULT 'Full-Time',
    monthly_fee DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    description TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS classrooms (
    id INT AUTO_INCREMENT PRIMARY KEY,
    grade_level_id INT NULL,
    class_name VARCHAR(100) NOT NULL, -- ឧ. ថ្នាក់ទី១A, ថ្នាក់ទី១B
    shift ENUM('Morning', 'Afternoon', 'Both') DEFAULT 'Morning',
    room_number VARCHAR(50) DEFAULT 'Room-01',
    capacity INT DEFAULT 30,
    academic_year VARCHAR(50) NOT NULL DEFAULT '2025-2026',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (grade_level_id) REFERENCES grade_levels(id) ON DELETE SET NULL,
    INDEX idx_classroom_grade (grade_level_id),
    INDEX idx_classroom_shift (shift)
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
    gender ENUM('Male', 'Female') DEFAULT 'Male',
    dob DATE NULL,
    phone VARCHAR(50) NULL,
    email VARCHAR(150) NULL,
    role_title VARCHAR(100) DEFAULT 'គ្រូបង្រៀន',
    specialized_subject VARCHAR(150) NULL,
    degree VARCHAR(150) NULL, -- បរិញ្ញាបត្រ, អនុបណ្ឌិត
    employment_type ENUM('Full-Time', 'Part-Time', 'Contract') DEFAULT 'Full-Time',
    base_salary DECIMAL(10,2) DEFAULT 0.00,
    status VARCHAR(50) DEFAULT 'Active',
    hire_date DATE NULL,
    photo_url LONGTEXT NULL,
    telegram_chat_id VARCHAR(100) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_teacher_code (teacher_code),
    INDEX idx_teacher_status (status)
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
    gender ENUM('Male', 'Female') DEFAULT 'Female',
    dob DATE NULL,
    pob VARCHAR(255) NULL,
    current_address TEXT NULL,
    
    -- Guardian & Emergency Contact Info
    parent_name VARCHAR(150) NULL,
    parent_relation VARCHAR(50) DEFAULT 'Father',
    parent_occupation VARCHAR(100) NULL,
    parent_phone VARCHAR(50) NULL, -- លេខទូរស័ព្ទចម្បង
    emergency_phone VARCHAR(50) NULL, -- លេខទាន់ហេតុការណ៍ទី២
    telegram_chat_id VARCHAR(100) NULL, -- សម្រាប់ Notification
    
    -- Academic Details
    study_type ENUM('Full-Time', 'Part-Time') NOT NULL DEFAULT 'Full-Time',
    shift ENUM('Morning', 'Afternoon', 'Both') DEFAULT 'Morning',
    part_time_course ENUM('English', 'Chinese', 'Computer', 'None') DEFAULT 'None',
    classroom_id INT NULL,
    photo_url LONGTEXT NULL,
    status ENUM('Active', 'Suspended', 'Graduated', 'Dropped') DEFAULT 'Active',
    
    -- Health & Notes
    allergies_notes TEXT NULL,
    health_notes TEXT NULL,
    special_notes TEXT NULL,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (classroom_id) REFERENCES classrooms(id) ON DELETE SET NULL,
    INDEX idx_student_code (student_code),
    INDEX idx_student_classroom (classroom_id),
    INDEX idx_student_status (status),
    INDEX idx_student_name_kh (name_kh)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------------------------
-- ៥. ATTENDANCE (ប្រព័ន្ធកត់ត្រាវត្តមានល្បឿនលឿន)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS attendance (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    classroom_id INT NULL,
    date DATE NOT NULL,
    shift ENUM('Morning', 'Afternoon') DEFAULT 'Morning',
    status ENUM('Present', 'Late', 'Absent', 'Permission') DEFAULT 'Present',
    method ENUM('QR_Scan', 'Manual_Bulk', 'Web') DEFAULT 'QR_Scan',
    note VARCHAR(255) NULL,
    scanned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    FOREIGN KEY (classroom_id) REFERENCES classrooms(id) ON DELETE SET NULL,
    UNIQUE KEY uq_student_date_shift (student_id, date, shift),
    INDEX idx_attendance_date (date),
    INDEX idx_attendance_student_date (student_id, date),
    INDEX idx_attendance_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------------------------
-- ៦. SCHEDULES & SUBJECTS (កាលវិភាគ និងមុខវិជ្ជា)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS subjects (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name_kh VARCHAR(100) NOT NULL,
    name_en VARCHAR(100) NULL,
    code VARCHAR(50) UNIQUE NOT NULL,
    coefficient INT DEFAULT 1,
    description TEXT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS schedules (
    id INT AUTO_INCREMENT PRIMARY KEY,
    classroom_id INT NOT NULL,
    teacher_id INT NOT NULL,
    subject_name VARCHAR(100) NOT NULL,
    day_of_week ENUM('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday') NOT NULL,
    start_time VARCHAR(20) NOT NULL,
    end_time VARCHAR(20) NOT NULL,
    shift ENUM('Morning', 'Afternoon') DEFAULT 'Morning',
    FOREIGN KEY (classroom_id) REFERENCES classrooms(id) ON DELETE CASCADE,
    FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE CASCADE,
    INDEX idx_schedule_classroom (classroom_id),
    INDEX idx_schedule_teacher (teacher_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------------------------
-- ៧. GRADES & EXAMS (ពិន្ទុ មធ្យមភាគ និងចំណាត់ថ្នាក់)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS student_grades (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    classroom_id INT NOT NULL,
    subject_name VARCHAR(100) NOT NULL,
    month_name VARCHAR(50) NOT NULL, -- ឧ. 'មករា', 'កុម្ភៈ' ឬ 'Semester 1'
    attendance_score DECIMAL(5,2) DEFAULT 10.00,
    homework_score DECIMAL(5,2) DEFAULT 30.00,
    exam_score DECIMAL(5,2) DEFAULT 60.00,
    score DECIMAL(5,2) NOT NULL DEFAULT 0.00, -- Total = attendance + homework + exam
    grade_letter VARCHAR(5) DEFAULT 'F', -- A, B, C, D, E, F
    rank_in_class INT NULL,
    remarks TEXT NULL,
    recorded_by INT NULL, -- teacher user_id
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    FOREIGN KEY (classroom_id) REFERENCES classrooms(id) ON DELETE CASCADE,
    FOREIGN KEY (recorded_by) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_grades_student_month (student_id, month_name),
    INDEX idx_grades_classroom_month (classroom_id, month_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------------------------
-- ៨. BILLING, INVOICES & KHQR PAYMENTS (គ្រប់គ្រងការបង់ថ្លៃសិក្សា)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS invoices (
    id INT AUTO_INCREMENT PRIMARY KEY,
    invoice_no VARCHAR(50) UNIQUE NOT NULL,
    student_id INT NOT NULL,
    billing_month VARCHAR(50) NOT NULL,
    original_amount DECIMAL(10,2) NOT NULL,
    discount_type ENUM('Percentage', 'Fixed', 'None') DEFAULT 'None',
    discount_val DECIMAL(10,2) DEFAULT 0.00,
    net_amount DECIMAL(10,2) NOT NULL,
    due_date DATE NOT NULL,
    status ENUM('Pending', 'Under_Review', 'Paid', 'Cancelled') DEFAULT 'Pending',
    slip_image_url LONGTEXT NULL, -- បង្កាន់ដៃដែលអាណាព្យាបាល upload
    khqr_qr_data TEXT NULL,
    approved_by INT NULL,
    approved_at TIMESTAMP NULL,
    verified_by INT NULL,
    verified_at DATETIME NULL,
    rejection_reason VARCHAR(255) NULL,
    receipt_number VARCHAR(50) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    FOREIGN KEY (approved_by) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (verified_by) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_invoice_student (student_id),
    INDEX idx_invoice_status (status),
    INDEX idx_status_verification (status, verified_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS student_payments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    invoice_no VARCHAR(50) UNIQUE NOT NULL,
    student_id INT NOT NULL,
    invoice_id INT NULL,
    amount DECIMAL(10,2) NOT NULL,
    paid_date DATE NOT NULL,
    payment_method ENUM('Cash', 'KHQR', 'Bank Transfer') DEFAULT 'KHQR',
    transaction_ref VARCHAR(100) NULL,
    received_by VARCHAR(100) NULL,
    note VARCHAR(255) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE SET NULL,
    INDEX idx_payment_student_date (student_id, paid_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------------------------
-- ៩. AUDIT LOGS (កត់ត្រាសកម្មភាពសំខាន់ៗ ដើម្បីសុវត្ថិភាព)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS audit_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NULL,
    user_name VARCHAR(150) NULL,
    role VARCHAR(50) NULL,
    action VARCHAR(100) NOT NULL, -- CREATE, UPDATE, DELETE, APPROVE, SCAN
    table_name VARCHAR(100) NOT NULL, -- student_grades, student_payments, students
    record_id INT NULL,
    old_values JSON NULL,
    new_values JSON NULL,
    ip_address VARCHAR(50) NULL,
    user_agent TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_audit_table_record (table_name, record_id),
    INDEX idx_audit_action (action),
    INDEX idx_audit_time (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------------------------
-- ១០. DEFAULT SEED DATA
-- ------------------------------------------------------------------------------
INSERT INTO users (username, name, email, password, role)
VALUES ('admin', 'អ្នកគ្រប់គ្រងប្រព័ន្ធ', 'admin@brightlight.edu.kh', '$2a$10$wT3Wq7m3Zz1N2jR9Y5mY9OCW7S9g9Z3XgO4f1mC8sY8Z9K1M1m1m.', 'Admin')
ON DUPLICATE KEY UPDATE password = '$2a$10$wT3Wq7m3Zz1N2jR9Y5mY9OCW7S9g9Z3XgO4f1mC8sY8Z9K1M1m1m.';

INSERT INTO users (username, name, email, password, role)
VALUES ('accountant', 'គណនេយ្យករសាលា', 'accountant@brightlight.edu.kh', '$2a$10$wT3Wq7m3Zz1N2jR9Y5mY9OCW7S9g9Z3XgO4f1mC8sY8Z9K1M1m1m.', 'Accountant')
ON DUPLICATE KEY UPDATE password = '$2a$10$wT3Wq7m3Zz1N2jR9Y5mY9OCW7S9g9Z3XgO4f1mC8sY8Z9K1M1m1m.';

