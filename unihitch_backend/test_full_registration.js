const pool = require('./config/db');
const bcrypt = require('bcrypt');

async function testRegistration() {
    const client = await pool.connect();
    try {
        console.log('=== TESTING FULL REGISTRATION FLOW ===\n');

        // 1. Check current state
        console.log('1. Current database state:');
        const userCount = await client.query('SELECT COUNT(*) FROM usuario');
        console.log(`   Total users: ${userCount.rows[0].count}`);

        const walletCount = await client.query('SELECT COUNT(*) FROM wallet');
        console.log(`   Total wallets: ${walletCount.rows[0].count}`);

        const transCount = await client.query('SELECT COUNT(*) FROM transaccion');
        console.log(`   Total transactions: ${transCount.rows[0].count}\n`);

        // 2. Test registration with referral
        console.log('2. Testing registration with referral code...');

        await client.query('BEGIN');

        const testEmail = `test${Date.now()}@utp.edu.pe`;
        const hashedPassword = await bcrypt.hash('password123', 10);

        // Insert test user
        const userResult = await client.query(
            `INSERT INTO usuario (nombre, correo, password, telefono, id_universidad, verificado, tipo_usuario, es_agente_externo) 
             VALUES ($1, $2, $3, $4, $5, $6, $7, $8) 
             RETURNING id, nombre, correo`,
            ['Test User', testEmail, hashedPassword, '999999999', 1, false, 'ESTUDIANTE', false]
        );

        const newUser = userResult.rows[0];
        console.log(`   Created user: ID=${newUser.id}, Email=${newUser.correo}`);

        // Check if wallet was auto-created
        const walletCheck = await client.query('SELECT * FROM wallet WHERE id_usuario = $1', [newUser.id]);
        console.log(`   Wallet auto-created: ${walletCheck.rows.length > 0 ? 'YES' : 'NO'}`);

        if (walletCheck.rows.length > 0) {
            console.log(`   Wallet saldo: S/. ${walletCheck.rows[0].saldo}`);
        } else {
            console.log('   WARNING: Wallet was NOT auto-created by trigger!');
            console.log('   Creating wallet manually...');
            await client.query('INSERT INTO wallet (id_usuario, saldo) VALUES ($1, 0.00)', [newUser.id]);
        }

        // Process referral (assuming user 1 exists)
        const referrerId = 1;
        console.log(`\n3. Processing referral code for user ${referrerId}...`);

        const referrerCheck = await client.query('SELECT id FROM usuario WHERE id = $1', [referrerId]);

        if (referrerCheck.rows.length > 0) {
            // Update referrer wallet
            await client.query('UPDATE wallet SET saldo = saldo + 5 WHERE id_usuario = $1', [referrerId]);

            // Create transaction for referrer
            await client.query(
                `INSERT INTO transaccion (id_usuario, tipo, monto, descripcion) 
                 VALUES ($1, 'REFERIDO', 5.00, $2)`,
                [referrerId, `Recompensa por referir a ${newUser.nombre}`]
            );
            console.log(`   Added S/. 5 to referrer (ID ${referrerId})`);
            console.log(`   Created transaction for referrer`);

            // Update new user wallet
            await client.query('UPDATE wallet SET saldo = saldo + 3 WHERE id_usuario = $1', [newUser.id]);

            // Create transaction for new user
            await client.query(
                `INSERT INTO transaccion (id_usuario, tipo, monto, descripcion) 
                 VALUES ($1, 'BIENVENIDA', 3.00, 'Bono de bienvenida por registro con código de referido')`,
                [newUser.id]
            );
            console.log(`   Added S/. 3 to new user (ID ${newUser.id})`);
            console.log(`   Created transaction for new user`);
        } else {
            console.log(`   WARNING: Referrer ID ${referrerId} not found!`);
        }

        await client.query('COMMIT');
        console.log('\n4. Transaction COMMITTED successfully');

        // 5. Verify final state
        console.log('\n5. Final verification:');
        const finalWallet = await client.query('SELECT * FROM wallet WHERE id_usuario = $1', [newUser.id]);
        console.log(`   New user wallet saldo: S/. ${finalWallet.rows[0].saldo}`);

        const finalTrans = await client.query('SELECT * FROM transaccion WHERE id_usuario = $1', [newUser.id]);
        console.log(`   New user transactions: ${finalTrans.rows.length}`);

        if (referrerCheck.rows.length > 0) {
            const refWallet = await client.query('SELECT * FROM wallet WHERE id_usuario = $1', [referrerId]);
            console.log(`   Referrer wallet saldo: S/. ${refWallet.rows[0].saldo}`);

            const refTrans = await client.query('SELECT * FROM transaccion WHERE id_usuario = $1 ORDER BY fecha_transaccion DESC LIMIT 1', [referrerId]);
            if (refTrans.rows.length > 0) {
                console.log(`   Referrer last transaction: ${refTrans.rows[0].descripcion}`);
            }
        }

        console.log('\n=== TEST COMPLETED SUCCESSFULLY ===');

    } catch (error) {
        await client.query('ROLLBACK');
        console.error('\n!!! ERROR OCCURRED !!!');
        console.error('Error:', error.message);
        console.error('Code:', error.code);
        console.error('Detail:', error.detail);
        console.error('Hint:', error.hint);
    } finally {
        client.release();
        process.exit();
    }
}

testRegistration();
