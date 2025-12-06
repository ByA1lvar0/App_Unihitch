const pool = require('./config/db');

const checkLatestUser = async () => {
    try {
        // Get the latest registered user
        const result = await pool.query(`
            SELECT id, nombre, correo, es_agente_externo, id_universidad, fecha_registro
            FROM usuario
            ORDER BY fecha_registro DESC
            LIMIT 5
        `);

        console.log('Latest 5 registered users:');
        console.table(result.rows);

    } catch (err) {
        console.error('Error:', err.message);
    } finally {
        pool.end();
    }
};

checkLatestUser();
