CREATE TABLE IF NOT EXISTS teachers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNIQUE NOT NULL,                  
    teacher_code VARCHAR(50) UNIQUE NOT NULL,     
    name_kh VARCHAR(100) NOT NULL,                
    name_en VARCHAR(100) NOT NULL,                
    gender ENUM('Male', 'Female') NOT NULL,       
    dob DATE NULL,                                
    phone VARCHAR(50) NOT NULL,                   
    email VARCHAR(100) UNIQUE NOT NULL,           
    role_title VARCHAR(100) DEFAULT 'Teacher',    
    specialized_subject VARCHAR(150),             
    base_salary DECIMAL(10, 2) DEFAULT 0.00,      
    photo_url VARCHAR(255) DEFAULT 'default.png', 
    status VARCHAR(50) DEFAULT 'Active', 
    hire_date DATE NULL,                          
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
