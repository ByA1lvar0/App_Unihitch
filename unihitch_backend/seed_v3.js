const pool = require('./config/db');
const bcrypt = require('bcrypt');

const randomInt = (min, max) => Math.floor(Math.random() * (max - min + 1)) + min;
const randomElement = (arr) => arr[Math.floor(Math.random() * arr.length)];
const randomDate = (start, end) => new Date(start.getTime() + Math.random() * (end.getTime() - start.getTime()));

const LOCATIONS = ['Universidad de Piura', 'Real Plaza', 'Open Plaza', 'Campus UTP', 'Plaza de Armas', 'Aeropuerto', 'Santa Isabel', 'Ejidos'];

async function seedFinal() {
    try {
        console.log('🚀 Starting Final Seeding...');
        const passwordHash = await bcrypt.hash('123456', 10);

        const usersToCreate = [
            { name: 'Juan Perez', email: 'juan.perez@demo.com', phone: '900000001' },
            { name: 'Maria Gomez', email: 'maria.gomez@demo.com', phone: '900000002' },
            { name: 'Carlos Ruiz', email: 'carlos.ruiz@demo.com', phone: '900000003' },
            { name: 'Ana Lopez', email: 'ana.lopez@demo.com', phone: '900000004' },
            { name: 'Sofia Diaz', email: 'sofia.diaz@demo.com', phone: '900000005' },
            { name: 'Test User', email: 'test@demo.com', phone: '900000000' } // Ensure test user included
        ];

        let userIds = [];

        // 1. Create Users
        for (const u of usersToCreate) {
            let userId = null;
            // Try Select First
            try {
                const existing = await pool.query('SELECT id FROM usuario WHERE correo = $1', [u.email]);
                if (existing.rows.length > 0) {
                    userId = existing.rows[0].id;
                    console.log(`Found existing user: ${u.email}`);

                    // Force update password just in case
                    await pool.query('UPDATE usuario SET password=$1 WHERE id=$2', [passwordHash, userId]);
                }
            } catch (e) { }

            if (!userId) {
                try {
                    // NOTE: Using 'password' column correctly now
                    const res = await pool.query(
                        `INSERT INTO usuario (nombre, correo, password, telefono, rol, es_universitario, verificado, verificado_reniec) 
                         VALUES ($1, $2, $3, $4, 'USER', true, true, true) 
                         RETURNING id`,
                        [u.name, u.email, passwordHash, u.phone]
                    );
                    userId = res.rows[0].id;
                    console.log(`Created new user: ${u.email}`);
                } catch (e) {
                    console.error(`Failed to insert ${u.email}:`, e.message);
                    // If failed by phone, try to find user by phone and use it?
                    try {
                        const exPhone = await pool.query('SELECT id FROM usuario WHERE telefono = $1', [u.phone]);
                        if (exPhone.rows.length > 0) userId = exPhone.rows[0].id;
                    } catch (err) { }
                }
            }

            if (userId) userIds.push(userId);
        }
        console.log(`✅ Demo Users Ready: ${userIds.length}`);

        // 2. Historical Trips
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
                    const passengerId = randomElement(userIds.filter(id => id !== conductorId)) || userIds[0];
                    if (passengerId !== conductorId) {
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
                } catch (e) { console.error("Trip error:", e.message); }
            }
            console.log(`✅ Generated ${tripsCount} trips.`);
        }

        console.log('DONE');
        process.exit(0);
    } catch (e) {
        console.error(e);
        process.exit(1);
    }
}
seedFinal();
