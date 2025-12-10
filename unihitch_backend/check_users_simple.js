const pool = require('./config/db');

async function check() {
    try {
        const res = await pool.query("SELECT rol, COUNT(*) FROM usuario GROUP BY rol");
        console.log("ROLES FOUND:", JSON.stringify(res.rows, null, 2));
        process.exit(0);
    } catch (e) {
        console.error(e);
        process.exit(1);
    }
}
check();
