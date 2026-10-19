const mysql = require('mysql2/promise');

async function fixSalaries() {
    const pool = mysql.createPool({
        host: 'localhost',
        user: 'root',
        password: '',
        database: 'bls_school_db',
    });

    try {
        console.log("Fixing teacher_salaries...");
        await pool.query("ALTER TABLE teacher_salaries ADD COLUMN pay_slip_no VARCHAR(100) NULL AFTER id");
        await pool.query("ALTER TABLE teacher_salaries ADD COLUMN salary_month VARCHAR(50) NULL AFTER teacher_id");
        await pool.query("ALTER TABLE teacher_salaries CHANGE deduction deductions DECIMAL(10,2) DEFAULT 0.00");
        await pool.query("ALTER TABLE teacher_salaries CHANGE pay_date paid_date DATE NULL");
        console.log("Fixed teacher_salaries successfully!");
    } catch (e) {
        console.error("Error:", e.message);
    } finally {
        pool.end();
    }
}

fixSalaries();
