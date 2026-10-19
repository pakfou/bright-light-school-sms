const mysql = require('mysql2/promise');
const fs = require('fs');

async function fixDb() {
    const pool = mysql.createPool({
        host: 'localhost',
        user: 'root',
        password: '',
        database: 'bls_school_db',
        multipleStatements: true
    });

    try {
        console.log("Fixing students table...");
        
        // Ensure name_kh and name_en exist (we did this earlier, but just to be safe)
        try { await pool.query("ALTER TABLE students ADD COLUMN name_kh VARCHAR(100) AFTER student_code"); } catch(e){}
        try { await pool.query("ALTER TABLE students ADD COLUMN name_en VARCHAR(100) AFTER name_kh"); } catch(e){}
        
        // Remove old full_name
        try { await pool.query("ALTER TABLE students DROP COLUMN full_name"); } catch(e){}
        
        // Rename phone to parent_phone
        try { await pool.query("ALTER TABLE students CHANGE phone parent_phone VARCHAR(50)"); } catch(e){}
        
        // Add pob
        try { await pool.query("ALTER TABLE students ADD COLUMN pob VARCHAR(255) AFTER dob"); } catch(e){}
        
        // Add parent_name
        try { await pool.query("ALTER TABLE students ADD COLUMN parent_name VARCHAR(100) AFTER pob"); } catch(e){}

        console.log("Fixing teachers table by recreating it...");
        // Drop and recreate teachers
        await pool.query("DROP TABLE IF EXISTS teacher_attendance");
        await pool.query("DROP TABLE IF EXISTS teachers");

        const createTeachersSql = `
CREATE TABLE teachers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNIQUE NOT NULL,                  
    teacher_code VARCHAR(50) UNIQUE NOT NULL,     
    name_kh VARCHAR(100) NOT NULL,
    name_en VARCHAR(100) NOT NULL,
    gender ENUM('Male', 'Female') NOT NULL,
    dob DATE,                                     
    phone VARCHAR(50),
    email VARCHAR(100) UNIQUE,
    role_title VARCHAR(100) DEFAULT 'Teacher',    
    specialized_subject VARCHAR(255),             
    base_salary DECIMAL(10,2) DEFAULT 0.00,       
    status ENUM('Active', 'Inactive', 'Resigned') DEFAULT 'Active',
    hire_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;`;

        await pool.query(createTeachersSql);
        console.log("Database schema completely fixed!");
    } catch (e) {
        console.error("Error:", e);
    } finally {
        pool.end();
    }
}

fixDb();
