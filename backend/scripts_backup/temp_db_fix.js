const mysql = require('mysql2/promise');

async function fixDb() {
    const pool = mysql.createPool({
        host: 'localhost',
        user: 'root',
        password: '',
        database: 'bls_school_db',
    });

    try {
        console.log("Checking and fixing DB...");
        
        // 1. Fix photo_url columns
        await pool.query('ALTER TABLE students MODIFY COLUMN photo_url LONGTEXT NULL');
        console.log("students photo_url upgraded to LONGTEXT");
        
        await pool.query('ALTER TABLE teachers MODIFY COLUMN photo_url LONGTEXT NULL');
        console.log("teachers photo_url upgraded to LONGTEXT");

        // 2. Check teacher_id in attendance
        const [columns] = await pool.query("SHOW COLUMNS FROM attendance LIKE 'teacher_id'");
        if (columns.length === 0) {
            await pool.query('ALTER TABLE attendance ADD COLUMN teacher_id INT NULL AFTER student_id');
            console.log("Added teacher_id column to attendance");
        } else {
            console.log("teacher_id already exists in attendance");
        }

        console.log("Database fixes applied successfully!");
    } catch (e) {
        console.error("Error fixing DB:", e.message);
    } finally {
        pool.end();
    }
}

fixDb();
