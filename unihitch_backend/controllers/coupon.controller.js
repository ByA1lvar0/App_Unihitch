const pool = require('../config/db');

// Validar cupón
const validateCoupon = async (req, res) => {
    try {
        const { codigo, userId } = req.body;

        const result = await pool.query(
            `SELECT c.*, 
              (SELECT COUNT(*) FROM cupon_uso WHERE id_cupon = c.id AND id_usuario = $2) as usos_usuario
       FROM cupon c
       WHERE c.codigo = $1 AND c.activo = TRUE`,
            [codigo, userId]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Cupón no encontrado o inactivo' });
        }

        const cupon = result.rows[0];

        // Validar expiración
        if (cupon.fecha_expiracion && new Date(cupon.fecha_expiracion) < new Date()) {
            return res.status(400).json({ error: 'Cupón expirado' });
        }

        // Validar usos máximos
        if (cupon.usos_maximos && cupon.usos_actuales >= cupon.usos_maximos) {
            return res.status(400).json({ error: 'Cupón agotado' });
        }

        // Validar si el usuario ya lo usó
        if (cupon.usos_usuario > 0) {
            return res.status(400).json({ error: 'Ya has usado este cupón' });
        }

        res.json({
            valido: true,
            cupon: {
                id: cupon.id,
                codigo: cupon.codigo,
                tipo: cupon.tipo,
                valor: cupon.valor,
                descripcion: cupon.descripcion
            }
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al validar cupón' });
    }
};

// Aplicar cupón
const applyCoupon = async (req, res) => {
    const client = await pool.connect();
    try {
        const { codigo, userId, tripId, montoOriginal } = req.body;

        await client.query('BEGIN');

        // Obtener cupón
        const cuponResult = await client.query(
            'SELECT * FROM cupon WHERE codigo = $1 AND activo = TRUE FOR UPDATE',
            [codigo]
        );

        if (cuponResult.rows.length === 0) {
            await client.query('ROLLBACK');
            return res.status(404).json({ error: 'Cupón no encontrado' });
        }

        const cupon = cuponResult.rows[0];

        // Calcular descuento
        let montoDescuento = 0;
        if (cupon.tipo === 'PORCENTAJE') {
            montoDescuento = (montoOriginal * cupon.valor) / 100;
        } else {
            montoDescuento = cupon.valor;
        }

        // No puede ser mayor al monto original
        montoDescuento = Math.min(montoDescuento, montoOriginal);

        // Registrar uso
        await client.query(
            'INSERT INTO cupon_uso (id_cupon, id_usuario, id_viaje, monto_descuento) VALUES ($1, $2, $3, $4)',
            [cupon.id, userId, tripId, montoDescuento]
        );

        // Incrementar usos
        await client.query(
            'UPDATE cupon SET usos_actuales = usos_actuales + 1 WHERE id = $1',
            [cupon.id]
        );

        await client.query('COMMIT');

        res.json({
            mensaje: 'Cupón aplicado exitosamente',
            monto_descuento: montoDescuento,
            monto_final: montoOriginal - montoDescuento
        });
    } catch (error) {
        await client.query('ROLLBACK');
        console.error(error);
        res.status(500).json({ error: 'Error al aplicar cupón' });
    } finally {
        client.release();
    }
};

// Crear cupón (admin)
const createCoupon = async (req, res) => {
    try {
        const { codigo, tipo, valor, descripcion, fechaExpiracion, usosMaximos, adminId } = req.body;

        const result = await pool.query(
            `INSERT INTO cupon (codigo, tipo, valor, descripcion, fecha_expiracion, usos_maximos, id_creador)
       VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *`,
            [codigo, tipo, valor, descripcion, fechaExpiracion, usosMaximos, adminId]
        );

        res.json({ mensaje: 'Cupón creado exitosamente', cupon: result.rows[0] });
    } catch (error) {
        console.error(error);
        if (error.code === '23505') {
            return res.status(400).json({ error: 'El código de cupón ya existe' });
        }
        res.status(500).json({ error: 'Error al crear cupón' });
    }
};

// Listar cupones activos
const getActiveCoupons = async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT id, codigo, tipo, valor, descripcion, fecha_expiracion, usos_maximos, usos_actuales
       FROM cupon
       WHERE activo = TRUE AND (fecha_expiracion IS NULL OR fecha_expiracion > NOW())
       ORDER BY fecha_creacion DESC`
        );

        res.json(result.rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al obtener cupones' });
    }
};

module.exports = { validateCoupon, applyCoupon, createCoupon, getActiveCoupons };
