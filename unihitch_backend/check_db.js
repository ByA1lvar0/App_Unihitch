const pool = require('./config/db');

async function checkDB() {
    try {
        console.log('Checking user 17...');
        const user = await pool.query('SELECT * FROM usuario WHERE id = 17');
        console.log('User:', user.rows);

        const count = await pool.query('SELECT count(*) FROM usuario');
        console.log('Total users:', count.rows[0].count);

        console.log('Checking wallet for user 17...');
        const wallet = await pool.query('SELECT * FROM wallet WHERE id_usuario = 17');
        console.log('Wallet:', wallet.rows);

    } catch (error) {
        console.error('Error:', error);
    } finally {
        process.exit();
    }
}

checkDB();
