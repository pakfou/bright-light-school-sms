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
        console.log('Altering students photo_url to LONGTEXT...');
        await pool.query('ALTER TABLE students MODIFY photo_url LONGTEXT').catch(e => console.log('Error:', e.message));
        
        console.log('Altering teachers photo_url to LONGTEXT...');
        await pool.query('ALTER TABLE teachers MODIFY photo_url LONGTEXT').catch(e => console.log('Error:', e.message));

        console.log('Altering users photo_url to LONGTEXT...');
        await pool.query('ALTER TABLE users MODIFY photo_url LONGTEXT').catch(e => console.log('Error:', e.message));

        console.log('Done!');
        process.exit(0);
    } catch (e) {
        console.error(e);
        process.exit(1);
    }
}

fixDB();
