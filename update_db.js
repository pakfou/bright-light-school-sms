require('dotenv').config({ path: './backend/.env' });
const mysql = require('mysql2/promise');

async function updateDB() {
    try {
        const dbName = process.env.DB_NAME || 'bls_school_db';
        const connConfig = {
            host: process.env.DB_HOST || 'localhost',
            user: process.env.DB_USER || 'root',
            password: process.env.DB_PASSWORD !== undefined ? process.env.DB_PASSWORD : '',
            port: process.env.DB_PORT ? parseInt(process.env.DB_PORT, 10) : 3306,
        };
        if (process.env.DB_SSL === 'true') {
            connConfig.ssl = { rejectUnauthorized: false };
        }

        const connection = await mysql.createConnection(connConfig);
        await connection.query(`CREATE DATABASE IF NOT EXISTS \`${dbName}\`;`);
        await connection.query(`USE \`${dbName}\`;`);

        const queries = [
            "ALTER TABLE users ADD COLUMN username VARCHAR(100) NULL AFTER name;",
            "ALTER TABLE users ADD COLUMN assigned_classroom_id INT NULL;",
            "ALTER TABLE teachers ADD COLUMN user_id INT NULL;",
            "ALTER TABLE teachers ADD COLUMN specialized_subject VARCHAR(150) NULL;",
            "ALTER TABLE teachers ADD COLUMN base_salary DECIMAL(10,2) DEFAULT 0.00;",
            "ALTER TABLE students ADD COLUMN study_type ENUM('Full-Time', 'Part-Time') DEFAULT 'Full-Time';",
            "ALTER TABLE students ADD COLUMN part_time_course VARCHAR(50) DEFAULT 'None';",
            "ALTER TABLE students ADD COLUMN photo_url VARCHAR(255) NULL;",
            `INSERT INTO users (username, name, email, password, role)
             VALUES ('admin', 'អ្នកគ្រប់គ្រងសាលា', 'admin@brightlight.edu.kh', '$2a$10$wT3Wq7m3Zz1N2jR9Y5mY9OCW7S9g9Z3XgO4f1mC8sY8Z9K1M1m1m.', 'Admin')
             ON DUPLICATE KEY UPDATE name = VALUES(name);`
        ];

        for (let q of queries) {
            try {
                await connection.query(q);
                console.log('Success:', q.substring(0, 50) + '...');
            } catch (err) {
                // Ignore "Duplicate column name" errors (code ER_DUP_FIELDNAME / 1060)
                if (err.code === 'ER_DUP_FIELDNAME') {
                    console.log('Column already exists, skipping:', q.substring(0, 50) + '...');
                } else {
                    console.error('Error executing query:', err.message);
                }
            }
        }

        console.log('Database updated successfully!');
        await connection.end();
    } catch (e) {
        console.error('Connection error:', e.message);
    }
}

updateDB();
