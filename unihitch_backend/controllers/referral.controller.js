const pool = require('../config/db');

// Generar código de referido único
function generateReferralCode(userId) {
    return `UNI${userId}${Math.random().toString(36).substring(2, 8).toUpperCase()}`;
}

// Obtener o generar código de referido
const getReferralCode = async (req, res) => {
    try {
        const { userId } = req.params;

        // Verificar si ya tiene código
        let result = await pool.query(
            'SELECT codigo_referido FROM usuario WHERE id = $1',
            [userId]
        );

        let codigo = result.rows[0]?.codigo_referido;

        // Si no tiene, generar uno
        if (!codigo) {
            codigo = generateReferralCode(userId);
            await pool.query(
                'UPDATE usuario SET codigo_referido = $1 WHERE id = $2',
                [codigo, userId]
            );
        }

        res.json({ codigo_referido: codigo });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al obtener código de referido' });
    }
};

// Aplicar código de referido
const applyReferralCode = async (req, res) => {
    const client = await pool.connect();
    try {
        const { userId, codigo } = req.body;

        await client.query('BEGIN');

        // Verificar que el usuario no se refiera a sí mismo
        const userCheck = await client.query(
            'SELECT codigo_referido FROM usuario WHERE id = $1',
            [userId]
        );

        if (userCheck.rows[0]?.codigo_referido === codigo) {
            await client.query('ROLLBACK');
            return res.status(400).json({ error: 'No puedes usar tu propio código' });
        }

        // Buscar al referidor
        const referidorResult = await client.query(
            'SELECT id FROM usuario WHERE codigo_referido = $1',
            [codigo]
        );

        if (referidorResult.rows.length === 0) {
            await client.query('ROLLBACK');
            return res.status(404).json({ error: 'Código de referido no válido' });
        }

        const idReferidor = referidorResult.rows[0].id;

        // Verificar si ya fue referido
        const existingRef = await client.query(
            'SELECT id FROM referido WHERE id_referido = $1',
            [userId]
        );

        if (existingRef.rows.length > 0) {
            await client.query('ROLLBACK');
            return res.status(400).json({ error: 'Ya has sido referido anteriormente' });
        }

        // Crear registro de referido
        await client.query(
            'INSERT INTO referido (id_referidor, id_referido, codigo_referido) VALUES ($1, $2, $3)',
            [idReferidor, userId, codigo]
        );

        // Dar recompensa al referidor (agregar a billetera)
        const montoRecompensa = 10.00;
        await client.query(
            'UPDATE billetera SET saldo = saldo + $1 WHERE id_usuario = $2',
            [montoRecompensa, idReferidor]
        );

        // Registrar transacción
        await client.query(
            `INSERT INTO transaccion (id_billetera, tipo, monto, descripcion)
       SELECT id, 'INGRESO', $1, 'Recompensa por referido'
       FROM billetera WHERE id_usuario = $2`,
            [montoRecompensa, idReferidor]
        );

        // Dar bono al nuevo usuario
        await client.query(
            'UPDATE billetera SET saldo = saldo + $1 WHERE id_usuario = $2',
            [5.00, userId]
        );

        await client.query(
            `INSERT INTO transaccion (id_billetera, tipo, monto, descripcion)
       SELECT id, 'INGRESO', $1, 'Bono de bienvenida por referido'
       FROM billetera WHERE id_usuario = $2`,
            [5.00, userId]
        );

        // Marcar recompensa como otorgada
        await client.query(
            'UPDATE referido SET recompensa_otorgada = TRUE WHERE id_referidor = $1 AND id_referido = $2',
            [idReferidor, userId]
        );

        await client.query('COMMIT');

        res.json({
            mensaje: 'Código de referido aplicado exitosamente',
            recompensa_referidor: montoRecompensa,
            bono_nuevo_usuario: 5.00
        });
    } catch (error) {
        await client.query('ROLLBACK');
        console.error(error);
        res.status(500).json({ error: 'Error al aplicar código de referido' });
    } finally {
        client.release();
    }
};

// Obtener estadísticas de referidos
const getReferralStats = async (req, res) => {
    try {
        const { userId } = req.params;

        const result = await pool.query(
            `SELECT 
         COUNT(*) as total_referidos,
         SUM(CASE WHEN recompensa_otorgada THEN monto_recompensa ELSE 0 END) as total_ganado
       FROM referido
       WHERE id_referidor = $1`,
            [userId]
        );

        const referidos = await pool.query(
            `SELECT u.nombre, u.correo, r.fecha, r.recompensa_otorgada, r.monto_recompensa
       FROM referido r
       JOIN usuario u ON r.id_referido = u.id
       WHERE r.id_referidor = $1
       ORDER BY r.fecha DESC`,
            [userId]
        );

        res.json({
            total_referidos: parseInt(result.rows[0].total_referidos),
            total_ganado: parseFloat(result.rows[0].total_ganado || 0),
            referidos: referidos.rows
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al obtener estadísticas' });
    }
};

module.exports = { getReferralCode, applyReferralCode, getReferralStats };
