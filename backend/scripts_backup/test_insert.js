const mysql = require('mysql2/promise');

async function testInsert() {
    const pool = mysql.createPool({
        host: 'localhost',
        user: 'root',
        password: '',
        database: 'bls_school_db',
    });

    try {
        console.log("Testing student insert...");
        await pool.query(
            `UPDATE students SET shift = ? WHERE id = 1809`,
            ['Both']
        );
        console.log("Student updated successfully.");
        
        console.log("Testing teacher insert...");
        await pool.query(
            `INSERT INTO teachers (teacher_code, name_kh, name_en, gender, dob, phone, email, role_title, specialized_subject, base_salary, hire_date, photo_url)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
            ['TCH-TEST', 'Test', 'Test', 'Male', '2000-01-01', '', '', 'Teacher', 'CS', 0.00, '2020-01-01', '']
        );
        console.log("Teacher inserted successfully.");

    } catch (e) {
        console.error("SQL ERROR:", e.message);
    } finally {
        pool.end();
    }
}

testInsert();
