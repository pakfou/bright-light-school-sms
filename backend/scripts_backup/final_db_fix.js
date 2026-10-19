const mysql = require('mysql2/promise');

async function fixDB() {
    const pool = mysql.createPool({
        host: 'localhost',
        user: 'root',
        password: '',
        database: 'bls_school_db',
    });

    try {
        console.log("Applying final DB fixes...");
        await pool.query("ALTER TABLE teachers MODIFY COLUMN photo_url LONGTEXT NULL");
        await pool.query("ALTER TABLE students MODIFY COLUMN photo_url LONGTEXT NULL");

        try {
            await pool.query("ALTER TABLE attendance ADD COLUMN shift ENUM('Morning', 'Afternoon') DEFAULT 'Morning'");
        } catch(e) {}
        try {
            await pool.query("ALTER TABLE attendance ADD COLUMN status ENUM('Present', 'Absent', 'Permission', 'Late') DEFAULT 'Present'");
        } catch(e) {}

        try {
            await pool.query("ALTER TABLE classrooms ADD COLUMN shift ENUM('Morning', 'Afternoon', 'Both') DEFAULT 'Morning'");
        } catch(e) {}
        try {
            await pool.query("ALTER TABLE classrooms ADD COLUMN room_number VARCHAR(50) DEFAULT 'Room-01'");
        } catch(e) {}
        try {
            await pool.query("ALTER TABLE classrooms ADD COLUMN capacity INT DEFAULT 30");
        } catch(e) {}

        console.log("Final DB fixes applied successfully!");
    } catch (e) {
        console.error("Error:", e.message);
    } finally {
        pool.end();
    }
}

fixDB();
