const pool = require('../config/db');

// Get emergency contacts for a user
const getEmergencyContacts = async (req, res) => {
    try {
        const { userId } = req.params;

        const result = await pool.query(
            'SELECT * FROM contactos_emergencia WHERE id_usuario = $1 ORDER BY es_principal DESC, fecha_creacion DESC',
            [userId]
        );

        res.json(result.rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al obtener contactos de emergencia' });
    }
};

// Add emergency contact
const addEmergencyContact = async (req, res) => {
    try {
        const { id_usuario, nombre, telefono, relacion, es_principal } = req.body;

        // If setting as principal, unset others
        if (es_principal) {
            await pool.query(
                'UPDATE contactos_emergencia SET es_principal = false WHERE id_usuario = $1',
                [id_usuario]
            );
        }

        const result = await pool.query(
            'INSERT INTO contactos_emergencia (id_usuario, nombre, telefono, relacion, es_principal) VALUES ($1, $2, $3, $4, $5) RETURNING *',
            [id_usuario, nombre, telefono, relacion, es_principal || false]
        );

        res.status(201).json(result.rows[0]);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al agregar contacto de emergencia' });
    }
};

// Update emergency contact
const updateEmergencyContact = async (req, res) => {
    try {
        const { id } = req.params;
        const { nombre, telefono, relacion, es_principal } = req.body;

        // Get user id first
        const contact = await pool.query('SELECT id_usuario FROM contactos_emergencia WHERE id = $1', [id]);

        if (contact.rows.length === 0) {
            return res.status(404).json({ error: 'Contacto no encontrado' });
        }

        // If setting as principal, unset others
        if (es_principal) {
            await pool.query(
                'UPDATE contactos_emergencia SET es_principal = false WHERE id_usuario = $1',
                [contact.rows[0].id_usuario]
            );
        }

        const result = await pool.query(
            'UPDATE contactos_emergencia SET nombre = $1, telefono = $2, relacion = $3, es_principal = $4 WHERE id = $5 RETURNING *',
            [nombre, telefono, relacion, es_principal, id]
        );

        res.json(result.rows[0]);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al actualizar contacto' });
    }
};

// Delete emergency contact
const deleteEmergencyContact = async (req, res) => {
    try {
        const { id } = req.params;

        await pool.query('DELETE FROM contactos_emergencia WHERE id = $1', [id]);

        res.json({ message: 'Contacto eliminado' });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al eliminar contacto' });
    }
};

// Get emergency configuration
const getEmergencyConfig = async (req, res) => {
    try {
        const { userId } = req.params;

        let result = await pool.query(
            'SELECT * FROM configuracion_emergencia WHERE id_usuario = $1',
            [userId]
        );

        // Create default config if doesn't exist
        if (result.rows.length === 0) {
            result = await pool.query(
                'INSERT INTO configuracion_emergencia (id_usuario) VALUES ($1) RETURNING *',
                [userId]
            );
        }

        res.json(result.rows[0]);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al obtener configuración' });
    }
};

// Update emergency configuration
const updateEmergencyConfig = async (req, res) => {
    try {
        const { userId } = req.params;
        const {
            auto_envio_ubicacion,
            notificar_universidad,
            grabar_audio,
            alertas_velocidad,
            velocidad_maxima
        } = req.body;

        const result = await pool.query(
            `INSERT INTO configuracion_emergencia 
       (id_usuario, auto_envio_ubicacion, notificar_universidad, grabar_audio, alertas_velocidad, velocidad_maxima, fecha_actualizacion)
       VALUES ($1, $2, $3, $4, $5, $6, NOW())
       ON CONFLICT (id_usuario) 
       DO UPDATE SET 
         auto_envio_ubicacion = $2,
         notificar_universidad = $3,
         grabar_audio = $4,
         alertas_velocidad = $5,
         velocidad_maxima = $6,
         fecha_actualizacion = NOW()
       RETURNING *`,
            [userId, auto_envio_ubicacion, notificar_universidad, grabar_audio, alertas_velocidad, velocidad_maxima]
        );

        res.json(result.rows[0]);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al actualizar configuración' });
    }
};

// Send emergency alert
const sendEmergencyAlert = async (req, res) => {
    try {
        const { userId, latitud, longitud } = req.body;

        // 1. Log alert in database
        const alertResult = await pool.query(
            'INSERT INTO alerta_emergencia (id_usuario, latitud, longitud) VALUES ($1, $2, $3) RETURNING *',
            [userId, latitud, longitud]
        );

        // 2. Get emergency contacts to simulate notification
        const contacts = await pool.query(
            'SELECT * FROM contactos_emergencia WHERE id_usuario = $1',
            [userId]
        );

        // 3. Create notifications for the user (simulation of system processing)
        if (contacts.rows.length > 0) {
            await pool.query(
                `INSERT INTO notificacion (id_usuario, titulo, mensaje, tipo) 
                 VALUES ($1, $2, $3, $4)`,
                [
                    userId,
                    'Alerta SOS Enviada',
                    `Se ha registrado tu alerta en: ${latitud}, ${longitud}. Notificando a ${contacts.rows.length} contactos.`,
                    'SISTEMA'
                ]
            );
        }

        res.json({
            success: true,
            alert: alertResult.rows[0],
            notifiedContacts: contacts.rows.length
        });

    } catch (error) {
        console.error('Error sending emergency alert:', error);
        res.status(500).json({ error: 'Error al enviar alerta de emergencia' });
    }
};

// Get emergency method preference (WHATSAPP or SMS)
const getEmergencyPreference = async (req, res) => {
    try {
        const { userId } = req.params;

        const result = await pool.query(
            'SELECT metodo_emergencia_preferido FROM usuario WHERE id = $1',
            [userId]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Usuario no encontrado' });
        }

        res.json({
            metodo_preferido: result.rows[0].metodo_emergencia_preferido || 'WHATSAPP'
        });
    } catch (error) {
        console.error('Error getting emergency preference:', error);
        res.status(500).json({ error: 'Error al obtener preferencia de emergencia' });
    }
};

// Update emergency method preference
const updateEmergencyPreference = async (req, res) => {
    try {
        const { userId } = req.params;
        const { metodo_preferido } = req.body;

        // Validate method
        if (!['WHATSAPP', 'SMS'].includes(metodo_preferido)) {
            return res.status(400).json({ error: 'Método inválido. Debe ser WHATSAPP o SMS' });
        }

        const result = await pool.query(
            'UPDATE usuario SET metodo_emergencia_preferido = $1 WHERE id = $2 RETURNING metodo_emergencia_preferido',
            [metodo_preferido, userId]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Usuario no encontrado' });
        }

        res.json({
            success: true,
            metodo_preferido: result.rows[0].metodo_emergencia_preferido
        });
    } catch (error) {
        console.error('Error updating emergency preference:', error);
        res.status(500).json({ error: 'Error al actualizar preferencia de emergencia' });
    }
};

module.exports = {
    getEmergencyContacts,
    addEmergencyContact,
    updateEmergencyContact,
    deleteEmergencyContact,
    getEmergencyConfig,
    updateEmergencyConfig,
    sendEmergencyAlert,
    getEmergencyPreference,
    updateEmergencyPreference
};
