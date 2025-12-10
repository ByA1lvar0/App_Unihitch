const pool = require('./config/db');
const bcrypt = require('bcrypt');

// Helpers
const randomInt = (min, max) => Math.floor(Math.random() * (max - min + 1)) + min;
const randomElement = (arr) => arr[Math.floor(Math.random() * arr.length)];
const randomBoolean = () => Math.random() < 0.5;
const randomDate = (start, end) => new Date(start.getTime() + Math.random() * (end.getTime() - start.getTime()));

const FIRST_NAMES = ['Carlos', 'Ana', 'Luis', 'Maria', 'Jorge', 'Lucia', 'Miguel', 'Sofia', 'Pedro', 'Elena'];
const LAST_NAMES = ['Perez', 'Garcia', 'Lopez', 'Rodriguez', 'Martinez', 'Sanchez', 'Romero', 'Diaz'];
const LOCATIONS = ['Universidad de Piura', 'Centro Comercial Real Plaza', 'Plaza de Armas', 'Aeropuerto', 'Urbanización Santa Isabel', 'Hospital Regional', 'Mercado Central', 'Campus UTP', 'Terminal Terrestre'];

async function safeQuery(text, params, label) {
    try {
        const res = await pool.query(text, params);
        return res;
    } catch (error) {
        console.error(`❌ Error in ${label}:`, error.message);
        console.error('Query:', text);
        // Don't throw, just return null so script continues or handles it
        return null;
    }
}

async function seedData() {
    try {
        console.log('🌱 Starting Robust Database Seeding...');
        const passwordHash = await bcrypt.hash('123456', 10);

        // 1. Create Extra Users
        const newUsers = [];
        for (let i = 0; i < 5; i++) {
            const nombre = `${randomElement(FIRST_NAMES)} ${randomElement(LAST_NAMES)}`;
            const correo = `user${randomInt(1000, 9999)}@example.com`;

            const res = await safeQuery(
                `INSERT INTO usuario (nombre, correo, contrasena, telefono, es_universitario, verificado_reniec) 
                 VALUES ($1, $2, $3, $4, true, true) 
                 ON CONFLICT (correo) DO NOTHING 
                 RETURNING id`,
                [nombre, correo, passwordHash, `9${randomInt(10000000, 99999999)}`],
                'Create User'
            );
            if (res && res.rows[0]) newUsers.push(res.rows[0].id);
        }
        console.log(`✅ Created ${newUsers.length} new users.`);

        // Get ALL users
        const allUsersResult = await safeQuery('SELECT id FROM usuario', [], 'Get Users');
        if (!allUsersResult) return;
        const allUserIds = allUsersResult.rows.map(u => u.id);

        if (allUserIds.length < 2) {
            console.log('Not enough users to create trips.');
            return;
        }

        // 2. Create Completed Trips
        let tripCount = 0;
        for (let i = 0; i < 15; i++) {
            const conductorId = randomElement(allUserIds);
            const origen = randomElement(LOCATIONS);
            let destino = randomElement(LOCATIONS);
            while (destino === origen) destino = randomElement(LOCATIONS);

            // Note: We deliberately exclude 'distancia_km' and 'tiempo_estimado' to avoid schema errors if they don't exist
            // Rely on defaults or nulls.
            const fecha = randomDate(new Date(Date.now() - 30 * 24 * 60 * 60 * 1000), new Date()); // Past 30 days
            const asientos = 4;
            const precio = randomInt(5, 15);

            const tripRes = await safeQuery(
                `INSERT INTO viaje (id_conductor, origen, destino, fecha_hora, asientos_totales, asientos_disponibles, estado, precio)
                 VALUES ($1, $2, $3, $4, $5, 0, 'COMPLETADO', $6)
                 RETURNING id`,
                [conductorId, origen, destino, fecha, asientos, precio],
                'Create Trip'
            );

            if (!tripRes || !tripRes.rows[0]) continue;
            const tripId = tripRes.rows[0].id;
            tripCount++;

            // 3. Create Reservations
            const passengerCount = randomInt(1, 3);
            const possiblePassengers = allUserIds.filter(id => id !== conductorId);

            for (let j = 0; j < passengerCount; j++) {
                if (possiblePassengers.length === 0) break;
                const passengerIndex = randomInt(0, possiblePassengers.length - 1);
                const passengerId = possiblePassengers.splice(passengerIndex, 1)[0];

                await safeQuery(
                    `INSERT INTO reserva (id_viaje, id_pasajero, asientos, precio_total, estado)
                     VALUES ($1, $2, 1, $3, 'COMPLETADA')`,
                    [tripId, passengerId, precio],
                    'Create Reservation'
                );

                // 4. Create Transactions (Simplified)
                // Try catch within safeQuery handles failures if 'metodo_pago' or cols missing
                // We guess columns based on previous errors: 
                // Try insert with metodo_pago 'WALLET'
                await safeQuery(
                    `INSERT INTO transaccion (id_usuario, tipo, monto, descripcion, metodo_pago)
                     VALUES ($1, 'PAGO_VIAJE', $2, $3, 'WALLET')`,
                    [passengerId, precio, `Pago viaje a ${destino}`],
                    'Create Transaction (Passenger)'
                );
            }

            // Driver Transaction
            await safeQuery(
                `INSERT INTO transaccion (id_usuario, tipo, monto, descripcion, metodo_pago)
                 VALUES ($1, 'COBRO_VIAJE', $2, $3, 'WALLET')`,
                [conductorId, precio * passengerCount, `Cobro viaje a ${destino}`],
                'Create Transaction (Driver)'
            );
        }
        console.log(`✅ Seeded ${tripCount} completed trips.`);

        console.log('🎉 Seeding DONE.');
        process.exit(0);
    } catch (error) {
        console.error('Fatal Seeding Error:', error);
        process.exit(1);
    }
}

seedData();
