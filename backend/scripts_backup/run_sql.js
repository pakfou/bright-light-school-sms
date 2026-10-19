const mysql = require('mysql2/promise');

async function run() {
    let connection;
    try {
        connection = await mysql.createConnection({
            host: 'localhost',
            user: 'root',
            password: '',
            database: 'bls_school_db',
        });
        console.log("Connected to DB...");
        
        // 1. Add username column
        try {
            await connection.query("ALTER TABLE users ADD COLUMN username VARCHAR(100) NULL AFTER name");
            console.log("Added column 'username' to users table.");
        } catch (e) {
            if (e.code === 'ER_DUP_FIELDNAME') console.log("'username' column already exists.");
            else console.log("Error adding 'username' column:", e.message);
        }

        // 2. Add status column
        try {
            await connection.query("ALTER TABLE users ADD COLUMN status VARCHAR(50) DEFAULT 'Active'");
            console.log("Added column 'status' to users table.");
        } catch (e) {
            if (e.code === 'ER_DUP_FIELDNAME') console.log("'status' column already exists.");
            else console.log("Error adding 'status' column:", e.message);
        }

        // 3. Create teachers table
        const createTeachers = `
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
            role_title VARCHAR(100) DEFAULT 'Teacher',
            specialized_subject VARCHAR(150) NULL,
            base_salary DECIMAL(10,2) DEFAULT 0.00,
            status VARCHAR(20) DEFAULT 'Active',
            hire_date DATE NULL,
            photo_url VARCHAR(255) NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
        )`;
        await connection.query(createTeachers);
        console.log("Teachers table created successfully.");

        // 4. Update admin
        await connection.query(`
            UPDATE users 
            SET password = '$2a$10$wT3Wq7m3Zz1N2jR9Y5mY9OCW7S9g9Z3XgO4f1mC8sY8Z9K1M1m1m.',
                username = 'admin'
            WHERE email = 'admin@brightlight.edu.kh'
        `);
        
        // 5. Insert admin if not exists
        await connection.query(`
            INSERT IGNORE INTO users (username, name, email, password, role, status)
            VALUES (
                'admin',
                'អ្នកគ្រប់គ្រងប្រព័ន្ធ', 
                'admin@brightlight.edu.kh', 
                '$2a$10$wT3Wq7m3Zz1N2jR9Y5mY9OCW7S9g9Z3XgO4f1mC8sY8Z9K1M1m1m.', 
                'Admin', 
                'Active'
            )
        `);
        console.log("Admin account updated.");
        
        console.log("Database update completed successfully!");
    } catch (e) {
        console.error("Critical Error:", e);
    } finally {
        if (connection) await connection.end();
    }
}
run();
