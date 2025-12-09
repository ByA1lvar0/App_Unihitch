const pool = require('./config/db');

async function addReferralCountColumn() {
    try {
        console.log('=== ADDING REFERRAL_COUNT COLUMN ===\n');

        // Check if column exists
        const check = await pool.query(`
            SELECT column_name 
            FROM information_schema.columns 
            WHERE table_name = 'usuario' AND column_name = 'referral_count'
        `);

        if (check.rows.length === 0) {
            console.log('Column referral_count does not exist. Adding it...');

            await pool.query(`
                ALTER TABLE usuario 
                ADD COLUMN referral_count INTEGER DEFAULT 0
            `);

            console.log('✅ Column referral_count added successfully');
        } else {
            console.log('ℹ️ Column referral_count already exists');
        }

        console.log('\n=== MIGRATION COMPLETED ===');

    } catch (error) {
        console.error('Error:', error.message);
    } finally {
        process.exit();
    }
}

addReferralCountColumn();
