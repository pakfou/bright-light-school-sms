const mysql = require('mysql2/promise');

async function fixDb() {
    try {
        const pool = mysql.createPool({
            host: 'localhost',
            user: 'root',
            password: '',
            database: 'bls_school_db',
            waitForConnections: true,
            connectionLimit: 10,
            queueLimit: 0
        });

        console.log("Checking students table...");
        const [studentCols] = await pool.query("SHOW COLUMNS FROM students");
        const studentColNames = studentCols.map(c => c.Field);
        
        if (!studentColNames.includes('name_kh')) {
            console.log("Adding name_kh to students...");
            await pool.query("ALTER TABLE students ADD COLUMN name_kh VARCHAR(100) AFTER student_code");
        }
        if (!studentColNames.includes('name_en')) {
            console.log("Adding name_en to students...");
            await pool.query("ALTER TABLE students ADD COLUMN name_en VARCHAR(100) AFTER name_kh");
        }

        console.log("Checking teachers table...");
        const [teacherCols] = await pool.query("SHOW COLUMNS FROM teachers");
        const teacherColNames = teacherCols.map(c => c.Field);

        if (!teacherColNames.includes('name_kh')) {
            console.log("Adding name_kh to teachers...");
            await pool.query("ALTER TABLE teachers ADD COLUMN name_kh VARCHAR(100) AFTER teacher_code");
        }
        if (!teacherColNames.includes('name_en')) {
            console.log("Adding name_en to teachers...");
            await pool.query("ALTER TABLE teachers ADD COLUMN name_en VARCHAR(100) AFTER name_kh");
        }

        console.log("Database schema fixed successfully!");
        process.exit(0);
    } catch (err) {
        console.error("Failed to fix DB:", err);
        process.exit(1);
    }
}

fixDb();
