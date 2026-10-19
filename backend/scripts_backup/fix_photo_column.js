const mysql = require('mysql2/promise');

async function fixDB() {
    const pool = mysql.createPool({
        host: 'localhost',
        user: 'root',
        password: '',
        database: 'bls_school_db',
        waitForConnections: true,
        connectionLimit: 10
    });

    try {
        console.log('Adding photo_url to students...');
        await pool.query('ALTER TABLE students ADD COLUMN photo_url VARCHAR(255) DEFAULT NULL').catch(e => console.log('Already exists or error:', e.message));
        
        console.log('Adding photo_url to teachers...');
        await pool.query('ALTER TABLE teachers ADD COLUMN photo_url VARCHAR(255) DEFAULT NULL').catch(e => console.log('Already exists or error:', e.message));

        console.log('Adding photo_url to users...');
        await pool.query('ALTER TABLE users ADD COLUMN photo_url VARCHAR(255) DEFAULT NULL').catch(e => console.log('Already exists or error:', e.message));

        console.log('Updating sample user...');
        await pool.query("UPDATE students SET photo_url = 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400&q=80' WHERE student_code = 'BLS-183133'").catch(e => console.log(e.message));

        console.log('Done!');
        process.exit(0);
    } catch (e) {
        console.error(e);
        process.exit(1);
    }
}

fixDB();
