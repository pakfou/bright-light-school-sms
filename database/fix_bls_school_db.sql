USE bls_school_db;

-- ធានាថាតារាង users មាន column 'username' និង 'status' ដែលចាំបាច់សម្រាប់កូដថ្មី
ALTER TABLE users ADD COLUMN IF NOT EXISTS username VARCHAR(100) NULL AFTER name;
ALTER TABLE users ADD COLUMN IF NOT EXISTS status VARCHAR(50) DEFAULT 'Active';

-- បង្កើតតារាង teachers ផ្ទុកទិន្នន័យទាំង ១៦ ចំណុច
CREATE TABLE IF NOT EXISTS teachers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NULL, -- ភ្ជាប់ទៅកាន់គណនី Login ក្នុងតារាង users
    teacher_code VARCHAR(50) UNIQUE NOT NULL,
    name_kh VARCHAR(150) NOT NULL,
    name_en VARCHAR(150) NULL,
    gender VARCHAR(10) DEFAULT 'Male',
    dob DATE NULL,
    phone VARCHAR(50) NULL,
    email VARCHAR(150) NULL,
    role_title VARCHAR(100) DEFAULT 'Teacher',
    specialized_subject VARCHAR(150) NULL,
    base_salary DECIMAL(10,2) DEFAULT 0.00,
    status VARCHAR(20) DEFAULT 'Active',
    hire_date DATE NULL,
    photo_url VARCHAR(255) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);

-- Update admin password
UPDATE users 
SET password = '$2a$10$wT3Wq7m3Zz1N2jR9Y5mY9OCW7S9g9Z3XgO4f1mC8sY8Z9K1M1m1m.',
    username = 'admin'
WHERE email = 'admin@brightlight.edu.kh';

-- Insert admin if missing
INSERT IGNORE INTO users (username, name, email, password, role, status)
VALUES (
    'admin',
    'អ្នកគ្រប់គ្រងប្រព័ន្ធ', 
    'admin@brightlight.edu.kh', 
    '$2a$10$wT3Wq7m3Zz1N2jR9Y5mY9OCW7S9g9Z3XgO4f1mC8sY8Z9K1M1m1m.', 
    'Admin', 
    'Active'
);
