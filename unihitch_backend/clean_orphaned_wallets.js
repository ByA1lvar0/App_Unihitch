const pool = require('./config/db');

async function cleanOrphanedWallets() {
    try {
        console.log('=== CLEANING ORPHANED WALLETS ===\n');

        // Find orphaned wallets
        const orphaned = await pool.query(`
            SELECT w.id_usuario 
            FROM wallet w 
            LEFT JOIN usuario u ON w.id_usuario = u.id 
            WHERE u.id IS NULL
        `);

        console.log(`Found ${orphaned.rows.length} orphaned wallets`);

        if (orphaned.rows.length > 0) {
            console.log('Orphaned wallet user IDs:', orphaned.rows.map(r => r.id_usuario).join(', '));

            // Delete orphaned wallets
            const result = await pool.query(`
                DELETE FROM wallet 
                WHERE id_usuario IN (
                    SELECT w.id_usuario 
                    FROM wallet w 
                    LEFT JOIN usuario u ON w.id_usuario = u.id 
                    WHERE u.id IS NULL
                )
            `);

            console.log(`Deleted ${result.rowCount} orphaned wallets`);
        }

        console.log('\n=== CLEANUP COMPLETED ===');

    } catch (error) {
        console.error('Error:', error.message);
    } finally {
        process.exit();
    }
}

cleanOrphanedWallets();
