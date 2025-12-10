const pool = require('./config/db');
const bcrypt = require('bcrypt');

// Helpers
const randomInt = (min, max) => Math.floor(Math.random() * (max - min + 1)) + min;
const randomElement = (arr) => arr[Math.floor(Math.random() * arr.length)];
const randomDate = (start, end) => new Date(start.getTime() + Math.random() * (end.getTime() - start.getTime()));

const LOCATIONS = ['Universidad de Piura', 'Real Plaza', 'Open Plaza', 'Campus UTP', 'Plaza de Armas', 'Aeropuerto', 'Santa Isabel', 'Ejidos'];

async function safeQuery(text, params) {
    try {
        const res = await pool.query(text, params);
        return res;
    } catch (e) {
        // console.log(`Query failed: ${text.substring(0, 50)}... Error: ${e.message}`);
        return null; // Return null on error
    }
}

async function seedV2() {
    try {
        console.log('🚀 Starting Seeding V2 (Historical + Credentials)...');
        const passwordHash = await bcrypt.hash('123456', 10);

        // 1. Create Specific Users with Known Credentials
        const usersToCreate = [
            { name: 'Juan Perez', email: 'juan.perez@demo.com' },
            { name: 'Maria Gomez', email: 'maria.gomez@demo.com' },
            { name: 'Carlos Ruiz', email: 'carlos.ruiz@demo.com' },
            { name: 'Ana Lopez', email: 'ana.lopez@demo.com' },
            { name: 'Sofia Diaz', email: 'sofia.diaz@demo.com' }
        ];

        let createdUserIds = [];

        for (const u of usersToCreate) {
            let userId = null;

            // 1. Try Insert
            try {
                const res = await pool.query(
                    `INSERT INTO usuario (nombre, correo, contrasena, telefono, rol, es_universitario, verificado, verificado_reniec) 
                     VALUES ($1, $2, $3, $4, 'USER', true, true, true) 
                     RETURNING id`,
                    [u.name, u.email, passwordHash, `9${randomInt(10000000, 99999999)}`]
                );
                userId = res.rows[0].id;
            } catch (e) {
                // 2. If fails (likely duplicate), Select
                try {
                    const existing = await pool.query('SELECT id FROM usuario WHERE correo = $1', [u.email]);
                    if (existing.rows.length > 0) {
                        userId = existing.rows[0].id;
                        // Force update to ensure they are verified demo users
                        await pool.query('UPDATE usuario SET verificado=true, rol=\'USER\' WHERE id=$1', [userId]);
                    }
                } catch (e2) {
                    console.error('Failed to recover user:', u.email, e2.message);
                }
            }

            if (userId) {
                createdUserIds.push(userId);
            }
        }
        console.log(`✅ 5 Demo Users Ready. IDs: ${createdUserIds.join(', ')}`);

        if (createdUserIds.length < 2) {
            console.log("Not enough users to create trips.");
            process.exit(1);
        }

        // 2. Generate Historical Data (Past 4 Months)
        let tripsCount = 0;

        for (let i = 0; i < 40; i++) { // 40 Trips
            const conductorId = randomElement(createdUserIds);
            const origen = randomElement(LOCATIONS);
            let destino = randomElement(LOCATIONS);
            while (destino === origen) destino = randomElement(LOCATIONS);

            // Date between 120 days ago and yesterday
            const fecha = randomDate(new Date(Date.now() - 120 * 24 * 60 * 60 * 1000), new Date(Date.now() - 24 * 60 * 60 * 1000));

            const precio = randomInt(5, 12);
            const asientos = 4;

            // Insert Trip
            const tripRes = await safeQuery(
                `INSERT INTO viaje (id_conductor, origen, destino, fecha_hora, asientos_totales, asientos_disponibles, estado, precio)
                 VALUES ($1, $2, $3, $4, $5, 0, 'COMPLETADO', $6)
                 RETURNING id`,
                [conductorId, origen, destino, fecha, asientos, precio]
            );

            if (!tripRes || !tripRes.rows[0]) continue;
            const tripId = tripRes.rows[0].id;
            tripsCount++;

            // Create Reservations (1-3 passengers)
            const passengersCount = randomInt(1, 3);
            const potentialPassengers = createdUserIds.filter(id => id !== conductorId);

            for (let k = 0; k < passengersCount; k++) {
                if (potentialPassengers.length === 0) break;
                const pIdx = randomInt(0, potentialPassengers.length - 1);
                const pId = potentialPassengers.splice(pIdx, 1)[0];

                await safeQuery(
                    `INSERT INTO reserva (id_viaje, id_pasajero, asientos, precio_total, estado, fecha_reserva)
                     VALUES ($1, $2, 1, $3, 'COMPLETADA', $4)`,
                    [tripId, pId, precio, fecha]
                );

                // Add transactions
                await safeQuery(
                    `INSERT INTO transaccion (id_usuario, tipo, monto, descripcion, fecha_transaccion, metodo_pago)
                     VALUES ($1, 'PAGO_VIAJE', $2, $3, $4, 'WALLET')`,
                    [pId, precio, `Viaje a ${destino}`, fecha]
                );
            }

            // Driver Transaction
            await safeQuery(
                `INSERT INTO transaccion (id_usuario, tipo, monto, descripcion, fecha_transaccion, metodo_pago)
                 VALUES ($1, 'COBRO_VIAJE', $2, $3, $4, 'WALLET')`,
                [conductorId, precio * passengersCount, `Cobro viaje a ${destino}`, fecha]
            );
        }
        console.log(`✅ Generated ${tripsCount} Historical Trips.`);

        console.log('\n=============================================');
        console.log('🔑 CREDENTIALS FOR TESTING:');
        usersToCreate.forEach(u => {
            console.log(`User: ${u.email}  |  Pass: 123456`);
        });
        console.log('=============================================\n');

        process.exit(0);
    } catch (e) {
        console.error('Fatal:', e);
        process.exit(1);
    }
}

seedV2();
