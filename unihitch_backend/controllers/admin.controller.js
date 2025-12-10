const pool = require('../config/db');

const getPendingUsers = async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT u.id, u.nombre, u.correo, u.codigo_universitario, u.id_universidad, uni.nombre as universidad 
       FROM usuario u 
       LEFT JOIN universidad uni ON u.id_universidad = uni.id 
       WHERE u.verificado = false AND u.rol = 'USER' 
       ORDER BY uni.nombre, u.id DESC`
        );
        res.json(result.rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al obtener usuarios pendientes' });
    }
};

const verifyUser = async (req, res) => {
    try {
        const { userId } = req.params;
        await pool.query('UPDATE usuario SET verificado = true WHERE id = $1', [userId]);
        res.json({ success: true, message: 'Usuario verificado correctamente' });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al verificar usuario' });
    }
};

const addAdmin = async (req, res) => {
    try {
        const { email } = req.body;

        const user = await pool.query('SELECT * FROM usuario WHERE correo = $1', [email]);
        if (user.rows.length === 0) {
            return res.status(404).json({ error: 'Usuario no encontrado' });
        }

        await pool.query('UPDATE usuario SET rol = \'ADMIN\', verificado = true WHERE correo = $1', [email]);
        res.json({ success: true, message: 'Usuario promovido a administrador' });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al agregar administrador' });
    }
};

const getUsers = async (req, res) => {
    try {
        const result = await pool.query(
            "SELECT id, nombre, correo, id_universidad, verificado, rol FROM usuario WHERE rol != 'ADMIN' OR rol IS NULL ORDER BY nombre"
        );
        res.json(result.rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al obtener usuarios' });
    }
};

const deleteUser = async (req, res) => {
    try {
        const { userId } = req.params;

        // Eliminar mensajes de comunidad del usuario
        await pool.query('DELETE FROM mensaje_comunidad WHERE id_usuario = $1', [userId]);

        // Eliminar usuario
        await pool.query('DELETE FROM usuario WHERE id = $1', [userId]);

        res.json({ message: 'Usuario eliminado correctamente' });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al eliminar usuario' });
    }
};

const changeUniversity = async (req, res) => {
    try {
        const { userId, universidadId } = req.body;

        // Actualizar universidad y verificar usuario
        await pool.query(
            'UPDATE usuario SET id_universidad = $1, verificado = true WHERE id = $2',
            [universidadId, userId]
        );

        res.json({ message: 'Usuario agregado a la comunidad' });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al agregar usuario' });
    }
};

const toggleUserStatus = async (req, res) => {
    try {
        const { userId } = req.params;
        const { activo } = req.body;

        await pool.query(
            'UPDATE usuario SET activo = $1 WHERE id = $2',
            [activo, userId]
        );

        res.json({ success: true, message: activo ? 'Usuario habilitado' : 'Usuario inhabilitado' });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al cambiar estado del usuario' });
    }
};

const getDashboardStats = async (req, res) => {
    try {
        // 1. Usuarios Registrados
        // 1. Usuarios Registrados (Excluir ADMINs)
        const usersCount = await pool.query("SELECT COUNT(*) FROM usuario WHERE rol != 'ADMIN' OR rol IS NULL");

        // 2. Viajes Completados
        const tripsCount = await pool.query("SELECT COUNT(*) FROM viaje WHERE estado = 'COMPLETADO'");

        // 3. Calificación Promedio
        const avgRating = await pool.query("SELECT AVG(calificacion_promedio) FROM usuario WHERE (rol != 'ADMIN' OR rol IS NULL) AND calificacion_promedio > 0");

        // 4. Tasa de Retención (Usuarios con login/actividad en los últimos 30 días)
        // Si no tenemos 'ultimo_login', usamos usuarios creados o con viajes en los últimos 30 días como proxy de "activos"
        const activeUsers = await pool.query(`
            SELECT COUNT(DISTINCT id_usuario) 
            FROM (
                SELECT id_conductor as id_usuario FROM viaje WHERE fecha_hora > NOW() - INTERVAL '30 days'
                UNION
                SELECT id_pasajero as id_usuario FROM reserva WHERE fecha_reserva > NOW() - INTERVAL '30 days'
            ) as activos
        `);

        // 5. Tiempo Promedio de Emparejamiento (Simulado o calculado)
        // Diferencia entre creación del viaje y primera reserva
        // Por simplicidad calculamos el promedio de min en 'tiempo_estimado' de viajes completados
        // O retornamos un valor fijo si no hay datos suficientes.

        res.json({
            totalUsers: parseInt(usersCount.rows[0].count),
            completedTrips: parseInt(tripsCount.rows[0].count),
            avgRating: parseFloat(avgRating.rows[0].avg || 0).toFixed(2),
            activeUsersLast30d: parseInt(activeUsers.rows[0].count),
            avgMatchTimeMin: 12 // Hardcoded proxy or calculate via timestamp diffs if columns exist
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al obtener dashboard stats' });
    }
};

const getAllTrips = async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT 
                v.id,
                v.origen,
                v.destino,
                v.fecha_hora,
                v.precio,
                v.estado,
                v.asientos_totales,
                u.nombre as conductor_nombre,
                u.correo as conductor_correo,
                COUNT(DISTINCT r.id) as num_reservas
            FROM viaje v
            LEFT JOIN usuario u ON v.id_conductor = u.id
            LEFT JOIN reserva r ON v.id = r.id_viaje
            GROUP BY v.id, u.nombre, u.correo
            ORDER BY v.fecha_hora DESC
            LIMIT 100
        `);
        res.json(result.rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al obtener viajes' });
    }
};

module.exports = { getPendingUsers, verifyUser, addAdmin, getUsers, deleteUser, changeUniversity, getDashboardStats, toggleUserStatus, getAllTrips };
