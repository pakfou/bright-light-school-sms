const mysql = require('mysql2/promise');

async function main() {
    const pool = mysql.createPool({
        host: 'localhost',
        user: 'root',
        password: '',
        database: 'bls_school_db',
        charset: 'utf8mb4'
    });

    const [tables] = await pool.query('SHOW TABLES');
    console.log('=== TABLES IN bls_school_db ===');
    for (const t of tables) {
        const name = Object.values(t)[0];
        const [[{ count }]] = await pool.query('SELECT COUNT(*) as count FROM `' + name + '`');
        console.log(`- ${name}: ${count} rows`);
    }

    console.log('\n=== CLASSROOMS ===');
    const [classrooms] = await pool.query('SELECT * FROM classrooms');
    console.log(classrooms);

    console.log('\n=== STUDENTS ===');
    const [students] = await pool.query('SELECT id, student_code, name_kh, name_en, gender, dob, classroom_id, status FROM students');
    console.log(students);

    console.log('\n=== TEACHERS ===');
    const [teachers] = await pool.query('SELECT id, teacher_code, name_kh, name_en, role_title, specialized_subject, status FROM teachers');
    console.log(teachers);

    console.log('\n=== GRADES / SCORES ===');
    try {
        const [grades] = await pool.query('SELECT * FROM grades LIMIT 10');
        console.log(grades);
    } catch(e) { console.log('Grades error:', e.message); }

    console.log('\n=== PAYMENTS / SALARIES ===');
    try {
        const [payments] = await pool.query('SELECT * FROM student_payments LIMIT 5');
        console.log('Student payments:', payments.length);
        const [salaries] = await pool.query('SELECT * FROM teacher_salaries LIMIT 5');
        console.log('Teacher salaries:', salaries.length);
    } catch(e) { console.log('Finance error:', e.message); }

    console.log('\n=== ATTENDANCE ===');
    const [attendance] = await pool.query('SELECT * FROM attendance ORDER BY id DESC LIMIT 10');
    console.log(attendance);

    await pool.end();
}

main().catch(console.error);
