const pool = require('./config/db');

async function listAllUsers() {
    try {
        console.log('=== ALL USERS IN DATABASE ===\n');

        const result = await pool.query(`
            SELECT u.id, u.nombre, u.correo, u.telefono, w.saldo, 
                   (SELECT COUNT(*) FROM transaccion WHERE id_usuario = u.id) as trans_count
            FROM usuario u
            LEFT JOIN wallet w ON u.id = w.id_usuario
            ORDER BY u.id ASC
        `);

        console.log(`Total users: ${result.rows.length}\n`);

        result.rows.forEach(user => {
            console.log(`ID: ${user.id}`);
            console.log(`  Name: ${user.nombre}`);
            console.log(`  Email: ${user.correo}`);
            console.log(`  Phone: ${user.telefono || 'N/A'}`);
            console.log(`  Wallet: S/. ${user.saldo || '0.00'}`);
            console.log(`  Transactions: ${user.trans_count}`);
            console.log('');
        });

    } catch (error) {
        console.error('Error:', error.message);
    } finally {
        process.exit();
    }
}

listAllUsers();
