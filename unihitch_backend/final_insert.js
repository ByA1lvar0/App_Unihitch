const pool = require('./config/db');
const bcrypt = require('bcrypt');

async function run() {
    try {
        const hash = await bcrypt.hash('123456', 10);

        // Minimal Insert with Correct Column Name: 'password'
        const query = "INSERT INTO usuario (nombre, correo, password, telefono, rol, verificado) VALUES ($1, $2, $3, $4, 'USER', true) RETURNING id";
        const values = ['Test User', 'test@demo.com', hash, '90000000'];

        console.log("Executing:", query);
        let u1 = await pool.query(query, values);
        console.log("User Created ID:", u1.rows[0].id);

        process.exit(0);
    } catch (e) {
        console.error("FULL ERROR:", e);
        process.exit(1);
    }
}
run();
