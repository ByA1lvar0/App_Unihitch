const pool = require('./config/db');
const bcrypt = require('bcrypt');

async function run() {
    try {
        const hash = await bcrypt.hash('123456', 10);
        console.log("Hash created.");

        // Insert User 1
        let u1 = await pool.query("INSERT INTO usuario (nombre, correo, contrasena, telefono, rol, es_universitario, verificado) VALUES ('Juan Demo', 'juan@demo.com', $1, '99999999', 'USER', true, true) ON CONFLICT (correo) DO UPDATE SET verificado=true RETURNING id", [hash]);
        let id1 = u1.rows[0].id;
        console.log("User 1 ID:", id1);

        // Insert User 2
        let u2 = await pool.query("INSERT INTO usuario (nombre, correo, contrasena, telefono, rol, es_universitario, verificado) VALUES ('Maria Demo', 'maria@demo.com', $1, '99999999', 'USER', true, true) ON CONFLICT (correo) DO UPDATE SET verificado=true RETURNING id", [hash]);
        let id2 = u2.rows[0].id;
        console.log("User 2 ID:", id2);

        // Trips
        const now = new Date();
        await pool.query("INSERT INTO viaje (id_conductor, origen, destino, fecha_hora, asientos_totales, asientos_disponibles, estado, precio) VALUES ($1, 'A', 'B', $2, 4, 0, 'COMPLETADO', 10)", [id1, now]);
        console.log("Trip created.");

        process.exit(0);
    } catch (e) {
        console.error("ERROR:", e);
        process.exit(1);
    }
}
run();
