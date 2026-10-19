const mysql = require('mysql2/promise');

async function main() {
    const pool = mysql.createPool({
        host: 'localhost',
        user: 'root',
        password: '',
        database: 'bls_school_db',
        charset: 'utf8mb4'
    });

    const [rows] = await pool.query('SELECT id, student_code, name_kh, name_en, classroom_id, photo_url FROM students');
    console.log('STUDENTS IN DB:', JSON.stringify(rows, null, 2));

    const [cols] = await pool.query('DESCRIBE students');
    console.log('STUDENTS COLS:', cols.map(c => c.Field));

    await pool.end();
}

main().catch(console.error);
