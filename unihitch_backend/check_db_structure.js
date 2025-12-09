const pool = require('./config/db');

async function checkDatabaseStructure() {
    try {
        console.log('=== CHECKING DATABASE STRUCTURE ===\n');

        // 1. Check if wallet trigger exists
        console.log('1. Checking for wallet auto-creation trigger:');
        const triggerCheck = await pool.query(`
            SELECT trigger_name, event_manipulation, event_object_table, action_statement
            FROM information_schema.triggers
            WHERE trigger_name LIKE '%wallet%'
        `);

        if (triggerCheck.rows.length > 0) {
            console.log('   Triggers found:');
            triggerCheck.rows.forEach(t => {
                console.log(`   - ${t.trigger_name} on ${t.event_object_table} (${t.event_manipulation})`);
            });
        } else {
            console.log('   WARNING: No wallet trigger found!');
            console.log('   Wallets must be created manually in the code.');
        }

        // 2. Check current data
        console.log('\n2. Current database content:');
        const users = await pool.query('SELECT id, nombre, correo FROM usuario ORDER BY id DESC LIMIT 5');
        console.log(`   Users (last 5):`);
        users.rows.forEach(u => {
            console.log(`   - ID: ${u.id}, Name: ${u.nombre}, Email: ${u.correo}`);
        });

        const wallets = await pool.query('SELECT id_usuario, saldo FROM wallet ORDER BY id_usuario DESC LIMIT 5');
        console.log(`\n   Wallets (last 5):`);
        wallets.rows.forEach(w => {
            console.log(`   - User ID: ${w.id_usuario}, Saldo: S/. ${w.saldo}`);
        });

        const transactions = await pool.query('SELECT id_usuario, tipo, monto, descripcion FROM transaccion ORDER BY fecha_transaccion DESC LIMIT 5');
        console.log(`\n   Transactions (last 5):`);
        transactions.rows.forEach(t => {
            console.log(`   - User ID: ${t.id_usuario}, Type: ${t.tipo}, Amount: S/. ${t.monto}, Desc: ${t.descripcion}`);
        });

        // 3. Check for orphaned wallets
        console.log('\n3. Checking for data consistency:');
        const orphanedWallets = await pool.query(`
            SELECT w.id_usuario 
            FROM wallet w 
            LEFT JOIN usuario u ON w.id_usuario = u.id 
            WHERE u.id IS NULL
        `);
        console.log(`   Orphaned wallets (wallet without user): ${orphanedWallets.rows.length}`);

        const usersWithoutWallet = await pool.query(`
            SELECT u.id, u.nombre 
            FROM usuario u 
            LEFT JOIN wallet w ON u.id = w.id_usuario 
            WHERE w.id_usuario IS NULL
        `);
        console.log(`   Users without wallet: ${usersWithoutWallet.rows.length}`);
        if (usersWithoutWallet.rows.length > 0) {
            console.log('   Users missing wallets:');
            usersWithoutWallet.rows.forEach(u => {
                console.log(`   - ID: ${u.id}, Name: ${u.nombre}`);
            });
        }

        console.log('\n=== CHECK COMPLETED ===');

    } catch (error) {
        console.error('Error:', error.message);
    } finally {
        process.exit();
    }
}

checkDatabaseStructure();
