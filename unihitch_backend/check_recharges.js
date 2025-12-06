const pool = require('./config/db');

async function checkPendingRecharges() {
    try {
        const res = await pool.query(`
      SELECT id, id_usuario, monto, metodo, estado, fecha_solicitud 
      FROM solicitudes_recarga 
      WHERE estado = 'PENDIENTE' 
      ORDER BY fecha_solicitud DESC
    `);

        console.log('--- Solicitudes Pendientes ---');
        if (res.rows.length === 0) {
            console.log('No hay solicitudes pendientes.');
        } else {
            res.rows.forEach(row => {
                console.log(`ID: ${row.id} | Usuario: ${row.id_usuario} | Monto: ${row.monto} | Método: ${row.metodo} | Fecha: ${row.fecha_solicitud}`);
            });
        }
        console.log('------------------------------');
    } catch (err) {
        console.error('Error querying database:', err);
    } finally {
        pool.end();
    }
}

checkPendingRecharges();
