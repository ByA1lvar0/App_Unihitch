const pool = require('./config/db');
require('dotenv').config();

const randomInt = (min, max) => Math.floor(Math.random() * (max - min + 1)) + min;
const randomElement = (arr) => arr[Math.floor(Math.random() * arr.length)];
const randomDate = (start, end) => new Date(start.getTime() + Math.random() * (end.getTime() - start.getTime()));

const LOCATIONS = ['Universidad de Piura', 'Real Plaza', 'Open Plaza', 'Campus UTP', 'Plaza de Armas', 'Aeropuerto', 'Santa Isabel', 'Ejidos'];

async function assignTripsToAngel() {
    try {
        console.log('🚀 Asignando viajes a Angel Zapata...');

        // Find Angel
        const angelRes = await pool.query("SELECT id, nombre, correo FROM usuario WHERE correo LIKE '%angel%' OR nombre LIKE '%Angel%' ORDER BY id LIMIT 1");

        if (angelRes.rows.length === 0) {
            console.log('❌ Angel no encontrado');
            process.exit(1);
        }

        const angel = angelRes.rows[0];
        console.log(`✅ Angel: ${angel.nombre} (${angel.correo}) - ID: ${angel.id}`);

        // Get other users for passengers
        const usersRes = await pool.query('SELECT id FROM usuario WHERE id != $1 LIMIT 5', [angel.id]);
        const passengerIds = usersRes.rows.map(u => u.id);

        // Create 15 trips for Angel (mix of past and future)
        let created = 0;
        for (let i = 0; i < 15; i++) {
            const origen = randomElement(LOCATIONS);
            let destino = randomElement(LOCATIONS);
            while (destino === origen) destino = randomElement(LOCATIONS);

            // Mix of past (completed) and future (available) trips
            const isPast = i < 10; // First 10 are past
            const fecha = isPast
                ? randomDate(new Date(Date.now() - 60 * 24 * 60 * 60 * 1000), new Date())
                : randomDate(new Date(), new Date(Date.now() + 30 * 24 * 60 * 60 * 1000));

            const precio = randomInt(5, 15);
            const estado = isPast ? 'COMPLETADO' : 'DISPONIBLE';
            const asientosDisponibles = isPast ? 0 : randomInt(1, 3);

            try {
                const tripRes = await pool.query(
                    `INSERT INTO viaje (id_conductor, origen, destino, fecha_hora, asientos_totales, asientos_disponibles, estado, precio)
                     VALUES ($1, $2, $3, $4, 4, $5, $6, $7)
                     RETURNING id`,
                    [angel.id, origen, destino, fecha, asientosDisponibles, estado, precio]
                );

                const tripId = tripRes.rows[0].id;
                created++;
                console.log(`  ✓ Viaje ${created}: ${origen} → ${destino} (${estado})`);

                // Add reservation if completed
                if (isPast && passengerIds.length > 0) {
                    const passengerId = randomElement(passengerIds);
                    await pool.query(
                        `INSERT INTO reserva (id_viaje, id_pasajero, asientos, precio_total, estado, fecha_reserva)
                         VALUES ($1, $2, 1, $3, 'COMPLETADA', $4)`,
                        [tripId, passengerId, precio, fecha]
                    );
                }
            } catch (e) {
                console.error(`  ✗ Error creando viaje ${i}:`, e.message);
            }
        }

        console.log(`\n✅ ${created} viajes creados para ${angel.nombre}`);
        console.log(`\n📧 Credenciales: ${angel.correo} | Contraseña: 123456`);
        process.exit(0);
    } catch (e) {
        console.error('❌ Error:', e);
        process.exit(1);
    }
}

assignTripsToAngel();
