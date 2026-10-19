const mysql = require('mysql2/promise');

async function testQuery() {
    const pool = mysql.createPool({
        host: 'localhost',
        user: 'root',
        password: '',
        database: 'bls_school_db',
    });

    try {
        await pool.query(`
            SELECT DATE_FORMAT(attendance.date, '%Y-%m-%d') AS date, 
                   COUNT(DISTINCT teacher_id) AS presentTeachers
            FROM attendance 
            WHERE teacher_id IS NOT NULL AND attendance.date >= DATE_SUB(CURDATE(), INTERVAL 6 DAY)
            GROUP BY attendance.date ORDER BY attendance.date ASC
        `);
        console.log("Query OK!");
    } catch (e) {
        console.error("SQL Error:", e.message);
    } finally {
        pool.end();
    }
}

testQuery();
