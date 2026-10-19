CREATE DATABASE IF NOT EXISTS bls_school_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE bls_school_db;

-- ១. USERS & ROLE-BASED LOGIN (Admin vs Teacher)
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role ENUM('Admin', 'Teacher') DEFAULT 'Teacher',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ២. CLASSROOMS
CREATE TABLE IF NOT EXISTS classrooms (
    id INT AUTO_INCREMENT PRIMARY KEY,
    class_name VARCHAR(100) NOT NULL,
    level_type ENUM('Full-Time', 'Part-Time') NOT NULL,
    shift ENUM('Morning', 'Afternoon', 'Weekend') NOT NULL,
    subject VARCHAR(100) DEFAULT 'General',
    room_number VARCHAR(50) DEFAULT 'Room 101',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ៣. TEACHER CLASS ASSIGNMENTS (សម្រាប់ Login តាមថ្នាក់)
CREATE TABLE IF NOT EXISTS teacher_classes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    teacher_id INT NOT NULL,
    classroom_id INT NOT NULL,
    FOREIGN KEY (teacher_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (classroom_id) REFERENCES classrooms(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ៤. STUDENTS MANAGEMENT
CREATE TABLE IF NOT EXISTS students (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_code VARCHAR(50) UNIQUE NOT NULL,
    name_kh VARCHAR(100) NOT NULL,
    name_en VARCHAR(100) NOT NULL,
    gender ENUM('Male', 'Female') NOT NULL,
    dob DATE NOT NULL,
    pob VARCHAR(255) NOT NULL,
    parent_name VARCHAR(100) NOT NULL,
    parent_phone VARCHAR(50) NOT NULL,
    study_type ENUM('Full-Time', 'Part-Time') NOT NULL,
    shift ENUM('Morning', 'Afternoon', 'Weekend') NOT NULL,
    classroom_id INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (classroom_id) REFERENCES classrooms(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ៥. DUAL ATTENDANCE (សិស្ស & គ្រូ)
CREATE TABLE IF NOT EXISTS student_attendance (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    classroom_id INT NOT NULL,
    scanned_by INT NOT NULL,
    date DATE NOT NULL,
    status ENUM('Present', 'Absent', 'Late', 'Permission') DEFAULT 'Present',
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    FOREIGN KEY (classroom_id) REFERENCES classrooms(id) ON DELETE CASCADE,
    FOREIGN KEY (scanned_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS teacher_attendance (
    id INT AUTO_INCREMENT PRIMARY KEY,
    teacher_id INT NOT NULL,
    date DATE NOT NULL,
    check_in TIME NOT NULL,
    check_out TIME NULL,
    status ENUM('Present', 'Late', 'Permission', 'Absent') DEFAULT 'Present',
    scanned_by INT NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (teacher_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (scanned_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ៦. GRADE ENTRY
CREATE TABLE IF NOT EXISTS student_grades (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    classroom_id INT NOT NULL,
    exam_title VARCHAR(100) NOT NULL,
    score DECIMAL(5,2) NOT NULL,
    grade_letter VARCHAR(5),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    FOREIGN KEY (classroom_id) REFERENCES classrooms(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ៧. TUITION & TEACHER SALARY FINANCE
CREATE TABLE IF NOT EXISTS student_payments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    discount DECIMAL(10,2) DEFAULT 0,
    payment_date DATE NOT NULL,
    status ENUM('Paid', 'Pending') DEFAULT 'Paid',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS teacher_salaries (
    id INT AUTO_INCREMENT PRIMARY KEY,
    teacher_id INT NOT NULL,
    base_salary DECIMAL(10,2) NOT NULL,
    bonus DECIMAL(10,2) DEFAULT 0,
    deduction DECIMAL(10,2) DEFAULT 0,
    net_salary DECIMAL(10,2) NOT NULL,
    pay_date DATE NOT NULL,
    FOREIGN KEY (teacher_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ៨. WEEKLY SCHEDULE
CREATE TABLE IF NOT EXISTS schedules (
    id INT AUTO_INCREMENT PRIMARY KEY,
    classroom_id INT NOT NULL,
    teacher_id INT NOT NULL,
    day_of_week ENUM('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday') NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    subject VARCHAR(100) NOT NULL,
    FOREIGN KEY (classroom_id) REFERENCES classrooms(id) ON DELETE CASCADE,
    FOREIGN KEY (teacher_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ៩. PERIODIC CLOSING REPORTS
CREATE TABLE IF NOT EXISTS periodic_closings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    closing_type ENUM('Daily', 'Weekly', 'Monthly', 'Yearly') NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    total_income DECIMAL(12,2) NOT NULL,
    total_expense DECIMAL(12,2) NOT NULL,
    net_profit DECIMAL(12,2) NOT NULL,
    closed_by INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (closed_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- បញ្ចូលគណនីគំរូ (Password គឺ 123456)
INSERT IGNORE INTO users (id, name, email, password, role) VALUES 
(1, 'Admin BLS', 'admin@bls.edu', '$2a$10$w3/h4eZkYm0aR35YtHqX1e7uYqNlH2eS2L3hA5H2J8g9X5u6.vW8O', 'Admin'),
(2, 'លោកគ្រូ សុខ', 'teacher@bls.edu', '$2a$10$w3/h4eZkYm0aR35YtHqX1e7uYqNlH2eS2L3hA5H2J8g9X5u6.vW8O', 'Teacher');

INSERT IGNORE INTO classrooms (id, class_name, level_type, shift, subject, room_number) VALUES 
(1, 'ថ្នាក់កុំព្យូទ័រ Level 1', 'Part-Time', 'Afternoon', 'កុំព្យូទ័ររដ្ឋបាល', 'Lab 1'),
(2, 'ថ្នាក់បឋម Grade 4A', 'Full-Time', 'Morning', 'ចំណេះទូទៅ', 'Room 201');

INSERT IGNORE INTO teacher_classes (teacher_id, classroom_id) VALUES (2, 1);
