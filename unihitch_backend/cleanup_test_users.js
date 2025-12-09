const pool = require('./config/db');

async function cleanupTestUsers() {
    const client = await pool.connect();
    try {
        console.log('=== CLEANING UP TEST USERS ===\n');

        await client.query('BEGIN');

        // Delete test users and their related data
        const result = await client.query(`
            DELETE FROM usuario 
            WHERE correo LIKE '%newuser%@utp.edu.pe' OR correo LIKE '%test%@utp.edu.pe'
            RETURNING id, nombre, correo
        `);

        console.log(`Deleted ${result.rowCount} test users:`);
        result.rows.forEach(u => {
            console.log(`  - ID ${u.id}: ${u.nombre} (${u.correo})`);
        });

        // Note: Wallets and transactions should be deleted automatically via CASCADE

        await client.query('COMMIT');
        console.log('\n=== CLEANUP COMPLETED ===');

    } catch (error) {
        await client.query('ROLLBACK');
        console.error('Error:', error.message);
    } finally {
        client.release();
        process.exit();
    }
}

cleanupTestUsers();
