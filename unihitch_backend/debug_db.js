const pool = require('./config/db');

async function debugTrip() {
    try {
        const tripId = 11;
        console.log(`--- DEBUGGING TRIP ${tripId} ---`);

        const trip = await pool.query('SELECT id, origen, destino FROM viaje WHERE id = $1', [tripId]);
        console.log('VIAJE FOUND:', trip.rows.length > 0);

        const reservas = await pool.query('SELECT id, id_pasajero, estado FROM reserva WHERE id_viaje = $1', [tripId]);
        console.log('RESERVAS COUNT:', reservas.rows.length);
        if (reservas.rows.length > 0) {
            console.log('STATUSES:', reservas.rows.map(r => r.estado));
        }

        process.exit(0);
    } catch (error) {
        console.error('Debug Error:', error);
        process.exit(1);
    }
}

debugTrip();
