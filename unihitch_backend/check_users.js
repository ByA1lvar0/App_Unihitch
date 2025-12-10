const pool = require('./config/db');

async function checkUsers() {
    try {
        console.log('--- USER ROLES CHECK ---');
        const res = await pool.query('SELECT id, nombre, rol FROM usuario LIMIT 10');
        console.table(res.rows);

        console.log('--- COUNT BY ROLE ---');
        const countRes = await pool.query('SELECT rol, COUNT(*) FROM usuario GROUP BY rol');
        console.table(countRes.rows);

        process.exit(0);
    } catch (e) {
        console.error(e);
        process.exit(1);
    }
}

checkUsers();
