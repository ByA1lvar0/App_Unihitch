const pool = require('./config/db');

async function debugWallet(userId) {
    try {
        console.log(`Debugging wallet for user ${userId}...`);

        // 1. Check Wallet
        console.log('Checking wallet table...');
        let wallet = await pool.query('SELECT * FROM wallet WHERE id_usuario = $1', [userId]);
        console.log('Wallet result:', wallet.rows);

        if (wallet.rows.length === 0) {
            console.log('Wallet not found, attempting to create...');
            // Simulate creation logic
            wallet = await pool.query(
                'INSERT INTO wallet (id_usuario, saldo) VALUES ($1, 0.00) RETURNING *',
                [userId]
            );
            console.log('Created wallet:', wallet.rows);
        }

        // 2. Check Transactions
        console.log('Checking transactions...');
        const transactions = await pool.query(
            'SELECT * FROM transaccion WHERE id_usuario = $1 ORDER BY fecha_transaccion DESC LIMIT 10',
            [userId]
        );
        console.log(`Found ${transactions.rows.length} transactions`);

        // 3. Check Pending Recharges
        console.log('Checking pending recharges...');
        const pendingRecharges = await pool.query(
            'SELECT * FROM comprobante_recarga WHERE id_usuario = $1 AND estado = \'PENDIENTE\' ORDER BY fecha_solicitud DESC',
            [userId]
        );
        console.log(`Found ${pendingRecharges.rows.length} pending recharges`);

        console.log('SUCCESS: Wallet data retrieved successfully');

    } catch (error) {
        console.error('ERROR OCCURRED:', error);
        if (error.code) console.error('Error Code:', error.code);
        if (error.detail) console.error('Error Detail:', error.detail);
        if (error.hint) console.error('Error Hint:', error.hint);
    } finally {
        process.exit();
    }
}

debugWallet(16);
