CREATE DATABASE IF NOT EXISTS bls_school_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE bls_school_db;

-- ១. កម្រិតសិក្សា (Full-Time / Part-Time)
CREATE TABLE IF NOT EXISTS grade_levels (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    study_type ENUM('Full-Time', 'Part-Time') NOT NULL DEFAULT 'Full-Time',
    description TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ២. ថ្នាក់រៀន
CREATE TABLE IF NOT EXISTS classrooms (
    id INT AUTO_INCREMENT PRIMARY KEY,
    grade_level_id INT NULL,
    class_name VARCHAR(100) NOT NULL,
    shift ENUM('Morning', 'Afternoon', 'Both') DEFAULT 'Morning',
    room_number VARCHAR(50) DEFAULT 'Room-01',
    capacity INT DEFAULT 30,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (grade_level_id) REFERENCES grade_levels(id) ON DELETE SET NULL
);

-- ៣. គណនី Admin
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(100) UNIQUE NOT NULL,
    name VARCHAR(150) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role ENUM('Admin', 'User') NOT NULL DEFAULT 'Admin',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ៤. ព័ត៌មានគ្រូបង្រៀន (១៦ ចំណុចពេញលេញ)
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
    base_salary DECIMAL(10,2) DEFAULT 0.00,
    status VARCHAR(50) DEFAULT 'Active',
    hire_date DATE NULL,
    photo_url VARCHAR(255) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);

-- ៥. ព័ត៌មានសិស្សានុសិស្ស (ពេញម៉ោង និងក្រៅម៉ោង)
CREATE TABLE IF NOT EXISTS students (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_code VARCHAR(50) UNIQUE NOT NULL,
    name_kh VARCHAR(150) NOT NULL,
    name_en VARCHAR(150) NULL,
    gender ENUM('Male', 'Female') DEFAULT 'Female',
    dob DATE NULL,
    pob VARCHAR(255) NULL,
    parent_name VARCHAR(150) NULL,
    parent_phone VARCHAR(50) NULL,
    study_type ENUM('Full-Time', 'Part-Time') NOT NULL DEFAULT 'Full-Time',
    shift ENUM('Morning', 'Afternoon', 'Both') DEFAULT 'Morning',
    part_time_course ENUM('English', 'Chinese', 'Computer', 'None') DEFAULT 'None',
    classroom_id INT NULL,
    photo_url VARCHAR(255) NULL,
    status VARCHAR(50) DEFAULT 'Active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (classroom_id) REFERENCES classrooms(id) ON DELETE SET NULL
);

-- ៦. កត់ត្រាវត្តមាន
CREATE TABLE IF NOT EXISTS attendance (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NULL,
    teacher_id INT NULL,
    classroom_id INT NULL,
    date DATE NOT NULL,
    shift ENUM('Morning', 'Afternoon') DEFAULT 'Morning',
    status ENUM('Present', 'Absent', 'Permission', 'Late') DEFAULT 'Present',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE CASCADE,
    FOREIGN KEY (classroom_id) REFERENCES classrooms(id) ON DELETE CASCADE
);

-- ៧. កាលវិភាគប្រចាំសប្តាហ៍
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
    FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE CASCADE
);

-- ៨. ពិន្ទុសិស្ស
CREATE TABLE IF NOT EXISTS student_grades (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    classroom_id INT NOT NULL,
    subject_name VARCHAR(100) NOT NULL,
    month_name VARCHAR(50) NOT NULL,
    score DECIMAL(5,2) NOT NULL DEFAULT 0.00,
    grade_letter VARCHAR(5) DEFAULT 'F',
    remarks TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    FOREIGN KEY (classroom_id) REFERENCES classrooms(id) ON DELETE CASCADE
);

-- ៩. ការបង់ថ្លៃសិក្សា
CREATE TABLE IF NOT EXISTS student_payments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    invoice_no VARCHAR(50) UNIQUE NOT NULL,
    student_id INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    paid_date DATE NOT NULL,
    payment_method ENUM('Cash', 'KHQR', 'Bank Transfer') DEFAULT 'KHQR',
    note VARCHAR(255) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE
);

-- ១០. ប្រាក់បៀវត្សរ៍គ្រូ
CREATE TABLE IF NOT EXISTS teacher_salaries (
    id INT AUTO_INCREMENT PRIMARY KEY,
    pay_slip_no VARCHAR(50) UNIQUE NOT NULL,
    teacher_id INT NOT NULL,
    salary_month VARCHAR(50) NOT NULL,
    base_salary DECIMAL(10,2) NOT NULL,
    bonus DECIMAL(10,2) DEFAULT 0.00,
    deductions DECIMAL(10,2) DEFAULT 0.00,
    net_salary DECIMAL(10,2) NOT NULL,
    paid_date DATE NOT NULL,
    status ENUM('Paid', 'Pending') DEFAULT 'Paid',
    FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE CASCADE
);

-- បង្កើតគណនី Admin និង គ្រូគំរូសម្រាប់ Login សាកល្បង
INSERT INTO users (username, name, email, password, role)
VALUES ('admin', 'អ្នកគ្រប់គ្រងប្រព័ន្ធ', 'admin@brightlight.edu.kh', '$2a$10$wT3Wq7m3Zz1N2jR9Y5mY9OCW7S9g9Z3XgO4f1mC8sY8Z9K1M1m1m.', 'Admin')
ON DUPLICATE KEY UPDATE password = '$2a$10$wT3Wq7m3Zz1N2jR9Y5mY9OCW7S9g9Z3XgO4f1mC8sY8Z9K1M1m1m.';

INSERT INTO teachers (teacher_code, name_kh, name_en, specialized_subject, base_salary, status)
VALUES ('TCH-1001', 'ហាក់ ប៉ាក់ហ៊្វូរ', 'HAK PAKFOU', 'វិទ្យាសាស្ត្រកុំព្យូទ័រ', 350.00, 'Active')
ON DUPLICATE KEY UPDATE name_kh = VALUES(name_kh);
