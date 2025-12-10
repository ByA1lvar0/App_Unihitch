const pool = require('./config/db');

async function checkSchema() {
    try {
        const res = await pool.query("SELECT py.attname, py.attnotnull, py.attnum FROM pg_attribute py JOIN pg_class pc ON pc.oid = py.attrelid WHERE pc.relname = 'usuario' AND py.attnum > 0");
        console.table(res.rows);
        process.exit(0);
    } catch (e) {
        console.error(e);
        process.exit(1);
    }
}
checkSchema();
