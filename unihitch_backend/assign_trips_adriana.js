const pool = require('./config/db');
const bcrypt = require('bcrypt');
require('dotenv').config();

const randomInt = (min, max) => Math.floor(Math.random() * (max - min + 1)) + min;
const randomElement = (arr) => arr[Math.floor(Math.random() * arr.length)];
const randomDate = (start, end) => new Date(start.getTime() + Math.random() * (end.getTime() - start.getTime()));

const LOCATIONS = ['Universidad de Piura', 'Real Plaza', 'Open Plaza', 'Campus UTP', 'Plaza de Armas', 'Aeropuerto', 'Santa Isabel', 'Ejidos'];

async function assignTripsToAdriana() {
    try {
        console.log('🚀 Asignando viajes a Adriana...');

        // Find Adriana
        const adrianaRes = await pool.query("SELECT id FROM usuario WHERE correo LIKE '%adriana%' OR nombre LIKE '%Adriana%' LIMIT 1");

        if (adrianaRes.rows.length === 0) {
            console.log('❌ Adriana no encontrada');
            process.exit(1);
        }

        const adrianaId = adrianaRes.rows[0].id;
        console.log(`✅ Adriana ID: ${adrianaId}`);

        // Get other users for passengers
        const usersRes = await pool.query('SELECT id FROM usuario WHERE id != $1 LIMIT 5', [adrianaId]);
        const passengerIds = usersRes.rows.map(u => u.id);

        // Create 10 trips for Adriana
        let created = 0;
        for (let i = 0; i < 10; i++) {
            const origen = randomElement(LOCATIONS);
            let destino = randomElement(LOCATIONS);
            while (destino === origen) destino = randomElement(LOCATIONS);

            const fecha = randomDate(new Date(Date.now() - 60 * 24 * 60 * 60 * 1000), new Date());
            const precio = randomInt(5, 12);
            const estado = fecha < new Date() ? 'COMPLETADO' : 'DISPONIBLE';

            try {
                const tripRes = await pool.query(
                    `INSERT INTO viaje (id_conductor, origen, destino, fecha_hora, asientos_totales, asientos_disponibles, estado, precio)
                     VALUES ($1, $2, $3, $4, 4, ${estado === 'COMPLETADO' ? 0 : randomInt(1, 3)}, $5, $6)
                     RETURNING id`,
                    [adrianaId, origen, destino, fecha, estado, precio]
                );

                const tripId = tripRes.rows[0].id;
                created++;

                // Add reservation if completed
                if (estado === 'COMPLETADO' && passengerIds.length > 0) {
                    const passengerId = randomElement(passengerIds);
                    await pool.query(
                        `INSERT INTO reserva (id_viaje, id_pasajero, asientos, precio_total, estado, fecha_reserva)
                         VALUES ($1, $2, 1, $3, 'COMPLETADA', $4)`,
                        [tripId, passengerId, precio, fecha]
                    );
                }
            } catch (e) {
                console.error(`Error creando viaje ${i}:`, e.message);
            }
        }

        console.log(`✅ ${created} viajes creados para Adriana`);
        process.exit(0);
    } catch (e) {
        console.error(e);
        process.exit(1);
    }
}

assignTripsToAdriana();
