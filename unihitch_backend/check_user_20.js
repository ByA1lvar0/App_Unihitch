const pool = require('./config/db');

async function checkUser20() {
    try {
        console.log('=== USER 20 DETAILS ===\n');

        const user = await pool.query('SELECT * FROM usuario WHERE id = 20');
        if (user.rows.length === 0) {
            console.log('User 20 not found!');
            process.exit();
        }

        console.log('User Info:');
        console.log(`  ID: ${user.rows[0].id}`);
        console.log(`  Name: ${user.rows[0].nombre}`);
        console.log(`  Email: ${user.rows[0].correo}`);
        console.log(`  Phone: ${user.rows[0].telefono}`);
        console.log(`  University ID: ${user.rows[0].id_universidad}`);

        const wallet = await pool.query('SELECT * FROM wallet WHERE id_usuario = 20');
        console.log('\nWallet Info:');
        if (wallet.rows.length > 0) {
            console.log(`  Saldo: S/. ${wallet.rows[0].saldo}`);
            console.log(`  Last Update: ${wallet.rows[0].fecha_actualizacion}`);
        } else {
            console.log('  NO WALLET FOUND!');
        }

        const transactions = await pool.query('SELECT * FROM transaccion WHERE id_usuario = 20 ORDER BY fecha_transaccion DESC');
        console.log(`\nTransactions: ${transactions.rows.length}`);
        transactions.rows.forEach((t, i) => {
            console.log(`  ${i + 1}. Type: ${t.tipo}, Amount: S/. ${t.monto}, Desc: ${t.descripcion}`);
            console.log(`     Date: ${t.fecha_transaccion}`);
        });

    } catch (error) {
        console.error('Error:', error.message);
    } finally {
        process.exit();
    }
}

checkUser20();
