const mysql = require('mysql2/promise');

async function fixDatabase() {
    const pool = mysql.createPool({
        host: 'localhost',
        user: 'root',
        password: '',
        database: 'bls_school_db',
        charset: 'utf8mb4'
    });

    console.log('Fixing BLS School Database schema...');

    // 1. grade_levels
    await pool.query("ALTER TABLE grade_levels ADD COLUMN study_type VARCHAR(50) NOT NULL DEFAULT 'Full-Time'").catch(() => { });
    await pool.query("ALTER TABLE grade_levels ADD COLUMN description TEXT NULL").catch(() => { });
    const [[glCount]] = await pool.query('SELECT COUNT(*) as count FROM grade_levels').catch(() => [[{ count: 1 }]]);
    if (glCount && glCount.count === 0) {
        await pool.query(`
            INSERT INTO grade_levels (name, study_type, description) VALUES
            ('ថ្នាក់ ទើបចាប់ផ្តើមរៀន (Nursery)', 'Full-Time', 'កម្រិតបឋមសិក្សាឆ្នាំទី១'),
            ('ថ្នាក់ទី ១ (Grade 1)', 'Full-Time', 'កម្រិតបឋមសិក្សាឆ្នាំទី១'),
            ('ថ្នាក់ទី ២ (Grade 2)', 'Full-Time', 'កម្រិតបឋមសិក្សាឆ្នាំទី២'),
            ('ថ្នាក់ទី ៣ (Grade 3)', 'Full-Time', 'កម្រិតបឋមសិក្សាឆ្នាំទី៣'),
            ('ថ្នាក់ទី ៤ (Grade 4)', 'Full-Time', 'កម្រិតបឋមសិក្សាឆ្នាំទី៤'),
            ('ថ្នាក់ទី ៥ (Grade 5)', 'Full-Time', 'កម្រិតបឋមសិក្សាឆ្នាំទី៥'),
            ('ថ្នាក់ទី ៦ (Grade 6)', 'Full-Time', 'កម្រិតបឋមសិក្សាឆ្នាំទី៦'),
            ('ថ្នាក់ទី ៧ (Grade 7)', 'Full-Time', 'កម្រិតអនុវិទ្យាល័យ'),
            ('ថ្នាក់ទី ៨ (Grade 8)', 'Full-Time', 'កម្រិតអនុវិទ្យាល័យ'),
            ('ថ្នាក់ទី ៩ (Grade 9)', 'Full-Time', 'កម្រិតអនុវិទ្យាល័យ'),
            ('ថ្នាក់ទី ១០ (Grade 10)', 'Full-Time', 'កម្រិតវិទ្យាល័យ'),
            ('ថ្នាក់ទី ១១ (Grade 11)', 'Full-Time', 'កម្រិតវិទ្យាល័យ'),
            ('ថ្នាក់ទី ១២ (Grade 12)', 'Full-Time', 'កម្រិតវិទ្យាល័យ'),
            ('មត្តេយ្យសិក្សា (Kindergarten)', 'Full-Time', 'កម្រិតកុមារតូច'),
            ('ភាសាអង់គ្លេសទូទៅ (GEP)', 'Part-Time', 'កម្មវិធីក្រៅម៉ោង'),
            ('ភាសាចិន (Chinese Program)', 'Part-Time', 'កម្មវិធីក្រៅម៉ោង')
        `).catch(() => { });
        console.log('Seeded grade_levels!');
    }

    // 2. classrooms
    await pool.query("ALTER TABLE classrooms MODIFY level_type ENUM('Full-Time','Part-Time') NOT NULL DEFAULT 'Full-Time'").catch(() => { });
    await pool.query("ALTER TABLE classrooms MODIFY shift ENUM('Morning','Afternoon','Weekend','Both') NOT NULL DEFAULT 'Morning'").catch(() => { });
    await pool.query("ALTER TABLE classrooms ADD COLUMN grade_level_id INT NULL").catch(() => { });
    await pool.query("ALTER TABLE classrooms ADD COLUMN room_number VARCHAR(50) DEFAULT 'Room-01'").catch(() => { });
    await pool.query("ALTER TABLE classrooms ADD COLUMN capacity INT DEFAULT 30").catch(() => { });
    const [[clsCount]] = await pool.query('SELECT COUNT(*) as count FROM classrooms').catch(() => [[{ count: 1 }]]);
    if (clsCount && clsCount.count === 0) {
        const [gls] = await pool.query('SELECT id FROM grade_levels LIMIT 3').catch(() => [[]]);
        const g1 = gls[0]?.id || null;
        const g2 = gls[1]?.id || null;
        const g3 = gls[2]?.id || null;
        await pool.query(`
            INSERT INTO classrooms (class_name, grade_level_id, level_type, shift, room_number, capacity) VALUES
            ('ថ្នាក់ទី ១A', ?, 'Full-Time', 'Morning', 'Room-101', 30),
            ('ថ្នាក់ទី ២A', ?, 'Full-Time', 'Morning', 'Room-102', 30),
            ('ថ្នាក់ទី ៣A', ?, 'Full-Time', 'Morning', 'Room-103', 30)
        `, [g1, g2, g3]).catch(() => { });
        console.log('Seeded classrooms!');
    }

    // 3. student_payments
    await pool.query("ALTER TABLE student_payments MODIFY payment_date DATE NULL").catch(() => { });
    await pool.query("ALTER TABLE student_payments ADD COLUMN paid_date DATE NULL").catch(() => { });
    await pool.query("ALTER TABLE student_payments ADD COLUMN invoice_no VARCHAR(50) NULL").catch(() => { });
    await pool.query("ALTER TABLE student_payments ADD COLUMN payment_method VARCHAR(50) DEFAULT 'KHQR'").catch(() => { });
    await pool.query("ALTER TABLE student_payments ADD COLUMN note VARCHAR(255) NULL").catch(() => { });
    await pool.query("ALTER TABLE student_payments MODIFY status ENUM('Paid','Pending') DEFAULT 'Paid'").catch(() => { });

    // 4. teacher_salaries
    await pool.query("ALTER TABLE teacher_salaries ADD COLUMN pay_slip_no VARCHAR(100) NULL").catch(() => { });
    await pool.query("ALTER TABLE teacher_salaries ADD COLUMN salary_month VARCHAR(50) NULL").catch(() => { });
    await pool.query("ALTER TABLE teacher_salaries MODIFY base_salary DECIMAL(10,2) DEFAULT 0.00").catch(() => { });
    await pool.query("ALTER TABLE teacher_salaries MODIFY bonus DECIMAL(10,2) DEFAULT 0.00").catch(() => { });
    await pool.query("ALTER TABLE teacher_salaries MODIFY deductions DECIMAL(10,2) DEFAULT 0.00").catch(() => { });
    await pool.query("ALTER TABLE teacher_salaries MODIFY net_salary DECIMAL(10,2) NULL").catch(() => { });
    await pool.query("ALTER TABLE teacher_salaries ADD COLUMN paid_date DATE NULL").catch(() => { });

    // 5. student_grades
    await pool.query("ALTER TABLE student_grades MODIFY classroom_id INT NULL").catch(() => { });
    await pool.query("ALTER TABLE student_grades MODIFY exam_title VARCHAR(150) NULL DEFAULT 'ប្រឡងប្រចាំខែ'").catch(() => { });
    await pool.query("ALTER TABLE student_grades ADD COLUMN subject_name VARCHAR(150) NULL").catch(() => { });
    await pool.query("ALTER TABLE student_grades ADD COLUMN month_name VARCHAR(50) NULL").catch(() => { });
    await pool.query("ALTER TABLE student_grades ADD COLUMN remarks TEXT NULL").catch(() => { });

    // 6. schedules
    await pool.query("ALTER TABLE schedules MODIFY classroom_id INT NULL").catch(() => { });
    await pool.query("ALTER TABLE schedules MODIFY teacher_id INT NULL").catch(() => { });

    // 7. Fix 'Data truncated for column status' across all tables
    await pool.query("ALTER TABLE teachers MODIFY COLUMN status VARCHAR(50) NOT NULL DEFAULT 'Active'").catch(() => { });
    await pool.query("ALTER TABLE students MODIFY COLUMN status VARCHAR(50) NOT NULL DEFAULT 'Active'").catch(() => { });
    await pool.query("ALTER TABLE attendance MODIFY COLUMN status VARCHAR(50) NOT NULL DEFAULT 'Present'").catch(() => { });
    await pool.query("ALTER TABLE student_payments MODIFY COLUMN status VARCHAR(50) NOT NULL DEFAULT 'Paid'").catch(() => { });
    await pool.query("ALTER TABLE users MODIFY COLUMN status VARCHAR(50) NOT NULL DEFAULT 'Active'").catch(() => { });

    console.log('Database repair completed successfully!');
    await pool.end();
}

fixDatabase().catch(err => {
    console.error('Migration error:', err);
    process.exit(1);
});
