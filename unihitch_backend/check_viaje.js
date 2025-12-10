const pool = require('./config/db');

async function checkSchema() {
    try {
        const res = await pool.query(`
            SELECT column_name 
            FROM information_schema.columns 
            WHERE table_name = 'viaje'
        `);
        console.log('Columns in VIAJE:', res.rows.map(r => r.column_name));
        process.exit(0);
    } catch (e) {
        console.log(e);
        process.exit(1);
    }
}
checkSchema();
