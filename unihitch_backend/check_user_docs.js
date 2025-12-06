const pool = require('./config/db');

async function checkUserDocs() {
    try {
        // Find user Adriana Elias
        const userRes = await pool.query("SELECT * FROM usuario WHERE nombre ILIKE '%Adriana Elias%'");

        if (userRes.rows.length === 0) {
            console.log('User not found');
            return;
        }

        const user = userRes.rows[0];
        console.log('User:', user.id, user.nombre, 'Es Agente:', user.es_agente_externo);

        // Check documents
        const docsRes = await pool.query("SELECT * FROM documentos_conductor WHERE id_conductor = $1", [user.id]);
        console.log('Documents:', docsRes.rows);

        // Check logic simulation
        const esAgenteExterno = user.es_agente_externo || false;
        const documentosRequeridos = esAgenteExterno
            ? ['SOAT', 'LICENCIA', 'DNI', 'TARJETA_MANTENIMIENTO', 'FOTO_PERFIL']
            : ['SOAT', 'LICENCIA', 'FOTO_PERFIL'];

        const documentos = {};
        docsRes.rows.forEach(doc => {
            documentos[doc.tipo_documento] = doc.estado;
        });

        const todosAprobados = documentosRequeridos.every(doc => documentos[doc] === 'APROBADO');
        console.log('Puede ofrecer viajes:', todosAprobados);

    } catch (err) {
        console.error(err);
    } finally {
        pool.end();
    }
}

checkUserDocs();
