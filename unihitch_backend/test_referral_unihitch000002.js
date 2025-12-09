const pool = require('./config/db');
const bcrypt = require('bcrypt');

async function testReferralRegistration() {
    const client = await pool.connect();
    try {
        console.log('=== TESTING REFERRAL REGISTRATION ===\n');

        // 1. Check referrer (user 2)
        const referrer = await client.query('SELECT id, nombre, correo FROM usuario WHERE id = 2');
        if (referrer.rows.length === 0) {
            console.log('ERROR: User 2 (referrer) does not exist!');
            process.exit();
        }

        console.log('Referrer Info:');
        console.log(`  ID: ${referrer.rows[0].id}`);
        console.log(`  Name: ${referrer.rows[0].nombre}`);
        console.log(`  Email: ${referrer.rows[0].correo}`);

        // Check referrer's current wallet
        const referrerWallet = await client.query('SELECT saldo FROM wallet WHERE id_usuario = 2');
        const initialBalance = referrerWallet.rows.length > 0 ? parseFloat(referrerWallet.rows[0].saldo) : 0;
        console.log(`  Current Wallet: S/. ${initialBalance.toFixed(2)}\n`);

        // 2. Register new user with referral code
        console.log('2. Registering new user with code UNIHITCH000002...');

        await client.query('BEGIN');

        const testEmail = `newuser${Date.now()}@utp.edu.pe`;
        const hashedPassword = await bcrypt.hash('password123', 10);

        // Insert new user
        const userResult = await client.query(
            `INSERT INTO usuario (nombre, correo, password, telefono, id_universidad, verificado, tipo_usuario, es_agente_externo) 
             VALUES ($1, $2, $3, $4, $5, $6, $7, $8) 
             RETURNING id, nombre, correo`,
            ['New Test User', testEmail, hashedPassword, '987654321', 1, false, 'ESTUDIANTE', false]
        );

        const newUser = userResult.rows[0];
        console.log(`   Created user: ID=${newUser.id}, Email=${newUser.correo}`);

        // Create wallet for new user
        await client.query('INSERT INTO wallet (id_usuario, saldo) VALUES ($1, 0.00)', [newUser.id]);
        console.log(`   Created wallet for user ${newUser.id}`);

        // Process referral code UNIHITCH000002
        const referralCode = 'UNIHITCH000002';
        const referrerId = parseInt(referralCode.replace('UNIHITCH', ''));

        console.log(`\n3. Processing referral code ${referralCode} (Referrer ID: ${referrerId})...`);

        // Verify referrer exists
        const referrerCheck = await client.query('SELECT id FROM usuario WHERE id = $1', [referrerId]);

        if (referrerCheck.rows.length > 0) {
            // Update referrer's referral count
            await client.query(
                'UPDATE usuario SET referral_count = COALESCE(referral_count, 0) + 1 WHERE id = $1',
                [referrerId]
            );

            // Add S/. 5 to referrer
            await client.query(
                'UPDATE wallet SET saldo = saldo + 5 WHERE id_usuario = $1',
                [referrerId]
            );

            // Create transaction for referrer
            await client.query(
                `INSERT INTO transaccion (id_usuario, tipo, monto, descripcion) 
                 VALUES ($1, 'REFERIDO', 5.00, $2)`,
                [referrerId, `Recompensa por referir a ${newUser.nombre}`]
            );
            console.log(`   ✅ Added S/. 5.00 to referrer (ID ${referrerId})`);
            console.log(`   ✅ Created transaction for referrer`);

            // Add S/. 3 to new user
            await client.query(
                'UPDATE wallet SET saldo = saldo + 3 WHERE id_usuario = $1',
                [newUser.id]
            );

            // Create transaction for new user
            await client.query(
                `INSERT INTO transaccion (id_usuario, tipo, monto, descripcion) 
                 VALUES ($1, 'BIENVENIDA', 3.00, 'Bono de bienvenida por registro con código de referido')`,
                [newUser.id]
            );
            console.log(`   ✅ Added S/. 3.00 to new user (ID ${newUser.id})`);
            console.log(`   ✅ Created transaction for new user`);
        }

        await client.query('COMMIT');
        console.log('\n4. ✅ TRANSACTION COMMITTED SUCCESSFULLY\n');

        // 5. Verify results
        console.log('5. Final Verification:');

        const newUserWallet = await client.query('SELECT saldo FROM wallet WHERE id_usuario = $1', [newUser.id]);
        console.log(`   New user wallet: S/. ${parseFloat(newUserWallet.rows[0].saldo).toFixed(2)}`);

        const newUserTrans = await client.query('SELECT tipo, monto, descripcion FROM transaccion WHERE id_usuario = $1', [newUser.id]);
        console.log(`   New user transactions: ${newUserTrans.rows.length}`);
        newUserTrans.rows.forEach(t => {
            console.log(`     - ${t.tipo}: S/. ${t.monto} - ${t.descripcion}`);
        });

        const referrerFinalWallet = await client.query('SELECT saldo FROM wallet WHERE id_usuario = 2');
        const finalBalance = parseFloat(referrerFinalWallet.rows[0].saldo);
        console.log(`\n   Referrer wallet: S/. ${initialBalance.toFixed(2)} → S/. ${finalBalance.toFixed(2)} (+S/. ${(finalBalance - initialBalance).toFixed(2)})`);

        const referrerTrans = await client.query('SELECT tipo, monto, descripcion FROM transaccion WHERE id_usuario = 2 ORDER BY fecha_transaccion DESC LIMIT 1');
        if (referrerTrans.rows.length > 0) {
            console.log(`   Referrer last transaction: ${referrerTrans.rows[0].descripcion}`);
        }

        console.log('\n=== ✅ TEST COMPLETED SUCCESSFULLY ===');

    } catch (error) {
        await client.query('ROLLBACK');
        console.error('\n!!! ❌ ERROR OCCURRED !!!');
        console.error('Error:', error.message);
        console.error('Code:', error.code);
    } finally {
        client.release();
        process.exit();
    }
}

testReferralRegistration();
