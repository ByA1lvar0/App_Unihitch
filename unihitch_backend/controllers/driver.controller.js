const pool = require('../config/db');

const uploadDocument = async (req, res) => {
    try {
        const {
            id_conductor,
            tipo_documento,
            archivo_base64,
            nombre_archivo,
            mime_type,
            tamanio_kb,
            fecha_vencimiento
        } = req.body;

        // Validar que el tipo de documento sea válido
        const tiposValidos = ['SOAT', 'LICENCIA', 'DNI', 'TARJETA_MANTENIMIENTO', 'FOTO_PERFIL', 'TARJETA_PROPIEDAD'];
        if (!tiposValidos.includes(tipo_documento)) {
            return res.status(400).json({
                error: 'Tipo de documento inválido',
                tipos_validos: tiposValidos
            });
        }

        // Verificar si ya existe un documento de este tipo para este conductor
        const existingDoc = await pool.query(
            'SELECT id FROM documentos_conductor WHERE id_conductor = $1 AND tipo_documento = $2',
            [id_conductor, tipo_documento]
        );

        let result;
        if (existingDoc.rows.length > 0) {
            // Actualizar documento existente
            result = await pool.query(
                `UPDATE documentos_conductor 
         SET archivo_base64 = $1, nombre_archivo = $2, mime_type = $3, tamanio_kb = $4, 
             fecha_vencimiento = $5, estado = 'PENDIENTE', fecha_subida = NOW()
         WHERE id_conductor = $6 AND tipo_documento = $7
         RETURNING *`,
                [archivo_base64, nombre_archivo, mime_type, tamanio_kb, fecha_vencimiento || null, id_conductor, tipo_documento]
            );
        } else {
            // Insertar nuevo documento
            result = await pool.query(
                `INSERT INTO documentos_conductor 
         (id_conductor, tipo_documento, archivo_base64, nombre_archivo, mime_type, tamanio_kb, fecha_vencimiento) 
         VALUES ($1, $2, $3, $4, $5, $6, $7) 
         RETURNING *`,
                [id_conductor, tipo_documento, archivo_base64, nombre_archivo, mime_type, tamanio_kb, fecha_vencimiento || null]
            );
        }

        // Crear notificación para todos los administradores
        try {
            const admins = await pool.query(
                'SELECT id FROM usuario WHERE es_admin = true'
            );

            const conductorInfo = await pool.query(
                'SELECT nombre FROM usuario WHERE id = $1',
                [id_conductor]
            );

            const nombreConductor = conductorInfo.rows[0]?.nombre || 'Un conductor';

            for (const admin of admins.rows) {
                await pool.query(
                    `INSERT INTO notificacion (id_usuario, tipo, titulo, mensaje, id_relacionado)
                     VALUES ($1, $2, $3, $4, $5)`,
                    [
                        admin.id,
                        'DOCUMENTO_PENDIENTE',
                        'Nuevo documento pendiente',
                        `${nombreConductor} ha subido un documento (${tipo_documento}) para revisión`,
                        result.rows[0].id
                    ]
                );
            }
        } catch (notifError) {
            console.error('Error al crear notificaciones:', notifError);
            // No fallar la subida si falla la notificación
        }

        res.json({
            mensaje: 'Documento subido exitosamente',
            documento: {
                id: result.rows[0].id,
                tipo_documento: result.rows[0].tipo_documento,
                estado: result.rows[0].estado,
                fecha_subida: result.rows[0].fecha_subida
            }
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al subir documento' });
    }
};

const getDocuments = async (req, res) => {
    try {
        const { id_conductor } = req.params;

        const result = await pool.query(
            `SELECT id, tipo_documento, nombre_archivo, estado, fecha_vencimiento, 
              motivo_rechazo, fecha_subida, fecha_revision, mime_type, tamanio_kb
       FROM documentos_conductor 
       WHERE id_conductor = $1
       ORDER BY fecha_subida DESC`,
            [id_conductor]
        );

        res.json(result.rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al obtener documentos' });
    }
};

const getDocumentStatus = async (req, res) => {
    try {
        const { id_conductor } = req.params;

        // Obtener tipo de usuario
        const userResult = await pool.query(
            'SELECT tipo_usuario, es_agente_externo FROM usuario WHERE id = $1',
            [id_conductor]
        );

        if (userResult.rows.length === 0) {
            return res.status(404).json({ error: 'Usuario no encontrado' });
        }

        const user = userResult.rows[0];
        const esAgenteExterno = user.es_agente_externo || false;

        // Documentos requeridos - igual que en trip.controller.js
        // Todos los conductores requieren los mismos 4 documentos básicos
        const documentosRequeridos = ['SOAT', 'LICENCIA', 'FOTO_PERFIL', 'TARJETA_PROPIEDAD'];

        // Obtener documentos subidos
        const docsResult = await pool.query(
            'SELECT tipo_documento, estado FROM documentos_conductor WHERE id_conductor = $1',
            [id_conductor]
        );

        const documentos = {};
        docsResult.rows.forEach(doc => {
            documentos[doc.tipo_documento] = doc.estado;
        });

        // Verificar cuales faltan
        const documentosFaltantes = documentosRequeridos.filter(doc => !documentos[doc]);
        const docsAprobados = Object.entries(documentos).filter(([_, estado]) => estado === 'APROBADO').map(([tipo, _]) => tipo);
        const docsPendientes = Object.entries(documentos).filter(([_, estado]) => estado === 'PENDIENTE').map(([tipo, _]) => tipo);
        const docsRechazados = Object.entries(documentos).filter(([_, estado]) => estado === 'RECHAZADO').map(([tipo, _]) => tipo);

        const todosAprobados = documentosRequeridos.every(doc => documentos[doc] === 'APROBADO');

        res.json({
            tipo_usuario: user.tipo_usuario,
            es_agente_externo: esAgenteExterno,
            documentos_requeridos: documentosRequeridos,
            documentos_faltantes: documentosFaltantes,
            documentos_aprobados: docsAprobados,
            documentos_pendientes: docsPendientes,
            documentos_rechazados: docsRechazados,
            puede_ofrecer_viajes: todosAprobados,
            estado_general: todosAprobados ? 'VERIFICADO' : (documentosFaltantes.length > 0 ? 'INCOMPLETO' : 'PENDIENTE_REVISION')
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al obtener estado de documentos' });
    }
};

// Aprobar documento
const approveDocument = async (req, res) => {
    const client = await pool.connect();
    try {
        const { id } = req.params;
        const { id_revisor } = req.body;

        await client.query('BEGIN');

        // Actualizar documento
        const result = await client.query(
            `UPDATE documentos_conductor 
             SET estado = 'APROBADO', fecha_revision = NOW(), id_revisor = $1, motivo_rechazo = NULL
             WHERE id = $2
             RETURNING id_conductor, tipo_documento`,
            [id_revisor, id]
        );

        if (result.rows.length === 0) {
            await client.query('ROLLBACK');
            return res.status(404).json({ error: 'Documento no encontrado' });
        }

        const { id_conductor, tipo_documento } = result.rows[0];

        // Crear notificación
        await client.query(
            `INSERT INTO notificacion (id_usuario, tipo, titulo, mensaje)
             VALUES ($1, 'DOCUMENTO_APROBADO', 'Documento Aprobado', $2)`,
            [id_conductor, `Tu documento ${tipo_documento} ha sido aprobado.`]
        );

        await client.query('COMMIT');

        res.json({ mensaje: 'Documento aprobado exitosamente' });
    } catch (error) {
        await client.query('ROLLBACK');
        console.error(error);
        res.status(500).json({ error: 'Error al aprobar documento' });
    } finally {
        client.release();
    }
};

// Rechazar documento
const rejectDocument = async (req, res) => {
    const client = await pool.connect();
    try {
        const { id } = req.params;
        const { id_revisor, motivo_rechazo } = req.body;

        if (!motivo_rechazo) {
            return res.status(400).json({ error: 'El motivo de rechazo es requerido' });
        }

        await client.query('BEGIN');

        // Actualizar documento
        const result = await client.query(
            `UPDATE documentos_conductor 
             SET estado = 'RECHAZADO', fecha_revision = NOW(), id_revisor = $1, motivo_rechazo = $2
             WHERE id = $3
             RETURNING id_conductor, tipo_documento`,
            [id_revisor, motivo_rechazo, id]
        );

        if (result.rows.length === 0) {
            await client.query('ROLLBACK');
            return res.status(404).json({ error: 'Documento no encontrado' });
        }

        const { id_conductor, tipo_documento } = result.rows[0];

        // Crear notificación
        await client.query(
            `INSERT INTO notificacion (id_usuario, tipo, titulo, mensaje)
             VALUES ($1, 'DOCUMENTO_RECHAZADO', 'Documento Rechazado', $2)`,
            [id_conductor, `Tu documento ${tipo_documento} fue rechazado. Motivo: ${motivo_rechazo}`]
        );

        await client.query('COMMIT');

        res.json({ mensaje: 'Documento rechazado' });
    } catch (error) {
        await client.query('ROLLBACK');
        console.error(error);
        res.status(500).json({ error: 'Error al rechazar documento' });
    } finally {
        client.release();
    }
};

// Obtener documentos pendientes (admin)
const getPendingDocuments = async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT d.*, u.nombre as conductor_nombre, u.correo as conductor_correo
             FROM documentos_conductor d
             JOIN usuario u ON d.id_conductor = u.id
             WHERE d.estado = 'PENDIENTE'
             ORDER BY d.fecha_subida ASC`
        );

        res.json(result.rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al obtener documentos pendientes' });
    }
};

module.exports = {
    uploadDocument,
    getDocuments,
    getDocumentStatus,
    approveDocument,
    rejectDocument,
    getPendingDocuments
};
