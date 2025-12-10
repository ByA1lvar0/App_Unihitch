const pool = require('./config/db');

async function check() {
    try {
        const fs = require('fs');
        const res = await pool.query("SELECT column_name FROM information_schema.columns WHERE table_name = 'usuario'");
        fs.writeFileSync('cols.txt', res.rows.map(c => c.column_name).join('\n'));
        console.log("Wrote to cols.txt");
        process.exit(0);
    } catch (e) { console.error(e); }
}
check();
