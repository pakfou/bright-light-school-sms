const mysql = require('mysql2/promise');

async function fixMoreDb() {
    const pool = mysql.createPool({
        host: 'localhost',
        user: 'root',
        password: '',
        database: 'bls_school_db',
    });

    try {
        console.log("Fixing teacher user_id...");
        await pool.query("ALTER TABLE teachers MODIFY COLUMN user_id INT NULL");
        console.log("Teacher user_id is now nullable!");

        console.log("Fixing student shift enum...");
        await pool.query("ALTER TABLE students MODIFY COLUMN shift ENUM('Morning','Afternoon','Both','Weekend') NOT NULL DEFAULT 'Morning'");
        console.log("Student shift enum updated!");

    } catch (e) {
        console.error("Error:", e.message);
    } finally {
        pool.end();
    }
}

fixMoreDb();
