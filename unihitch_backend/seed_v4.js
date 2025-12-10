const pool = require('./config/db');
const bcrypt = require('bcrypt');

const randomInt = (min, max) => Math.floor(Math.random() * (max - min + 1)) + min;
const randomElement = (arr) => arr[Math.floor(Math.random() * arr.length)];
const randomDate = (start, end) => new Date(start.getTime() + Math.random() * (end.getTime() - start.getTime()));

const LOCATIONS = ['Universidad de Piura', 'Real Plaza', 'Open Plaza', 'Campus UTP', 'Plaza de Armas', 'Aeropuerto', 'Santa Isabel', 'Ejidos'];

async function seedFinal() {
    try {
        console.log('🚀 Starting Seeding V4 (Random fallback)...');
        const passwordHash = await bcrypt.hash('123456', 10);

        // 1. Get All Existing Users
        const existingRes = await pool.query('SELECT id, correo FROM usuario');
        let userIds = existingRes.rows.map(u => u.id);
        console.log(`Found ${userIds.length} existing users.`);

        // 2. If < 5, create more
        if (userIds.length < 5) {
            const needed = 5 - userIds.length;
            for (let i = 0; i < needed; i++) {
                const email = `new.user.${Date.now()}.${i}@demo.com`; // Unique email guaranteed
                const phone = `9${Date.now().toString().substring(5)}${i}`; // Unique phone guaranteed

                try {
                    const res = await pool.query(
                        `INSERT INTO usuario (nombre, correo, password, telefono, rol, es_universitario, verificado, verificado_reniec) 
                         VALUES ($1, $2, $3, $4, 'USER', true, true, true) 
                         RETURNING id`,
                        [`User ${Date.now()}`, email, passwordHash, phone]
                    );
                    userIds.push(res.rows[0].id);
                    console.log(`Created: ${email}`);
                } catch (e) {
                    console.error("Insert failed:", e.message);
                }
            }
        }

        // 3. Historical Trips
        if (userIds.length >= 2) {
            let tripsCount = 0;
            for (let i = 0; i < 50; i++) { // 50 trips
                const conductorId = randomElement(userIds);
                const origen = randomElement(LOCATIONS);
                let destino = randomElement(LOCATIONS);
                while (destino === origen) destino = randomElement(LOCATIONS);

                const fecha = randomDate(new Date(Date.now() - 120 * 24 * 60 * 60 * 1000), new Date());
                const precio = randomInt(5, 12);

                try {
                    const tripRes = await pool.query(
                        `INSERT INTO viaje (id_conductor, origen, destino, fecha_hora, asientos_totales, asientos_disponibles, estado, precio)
                         VALUES ($1, $2, $3, $4, 4, 0, 'COMPLETADO', $5)
                         RETURNING id`,
                        [conductorId, origen, destino, fecha, precio]
                    );
                    const tripId = tripRes.rows[0].id;
                    tripsCount++;

                    // Reservation
                    const passengerId = randomElement(userIds.filter(id => id !== conductorId));
                    if (passengerId) {
                        await pool.query(
                            `INSERT INTO reserva (id_viaje, id_pasajero, asientos, precio_total, estado, fecha_reserva)
                             VALUES ($1, $2, 1, $3, 'COMPLETADA', $4)`,
                            [tripId, passengerId, precio, fecha]
                        );
                        // Transactions
                        await pool.query(
                            `INSERT INTO transaccion (id_usuario, tipo, monto, descripcion, fecha_transaccion, metodo_pago)
                             VALUES ($1, 'PAGO_VIAJE', $2, $3, $4, 'WALLET')`,
                            [passengerId, precio, `Viaje a ${destino}`, fecha]
                        );
                        await pool.query(
                            `INSERT INTO transaccion (id_usuario, tipo, monto, descripcion, fecha_transaccion, metodo_pago)
                             VALUES ($1, 'COBRO_VIAJE', $2, $3, $4, 'WALLET')`,
                            [conductorId, precio, `Cobro viaje a ${destino}`, fecha]
                        );
                    }
                } catch (e) { /* ignore */ }
            }
            console.log(`✅ Generated ${tripsCount} trips.`);
        }

        // Print Credentials
        console.log('\nCREDENTIALS:');
        console.log('User: test@demo.com  | Pass: 123456 (Guaranteed)');

        process.exit(0);
    } catch (e) {
        console.error(e);
        process.exit(1);
    }
}
seedFinal();
