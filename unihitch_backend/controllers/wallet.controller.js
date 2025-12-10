const pool = require('../config/db');

const getWallet = async (req, res) => {
    try {
        const { userId } = req.params;

        // First, verify the user exists
        const userCheck = await pool.query('SELECT id FROM usuario WHERE id = $1', [userId]);
        if (userCheck.rows.length === 0) {
            return res.status(404).json({ error: 'Usuario no encontrado' });
        }

        // Verificar si existe wallet, si no, crear uno
        let wallet = await pool.query('SELECT * FROM wallet WHERE id_usuario = $1', [userId]);

        if (wallet.rows.length === 0) {
            wallet = await pool.query(
                'INSERT INTO wallet (id_usuario, saldo) VALUES ($1, 0.00) RETURNING *',
                [userId]
            );
        }

        // Obtener últimas 10 transacciones
        const transactions = await pool.query(
            'SELECT * FROM transaccion WHERE id_usuario = $1 ORDER BY fecha_transaccion DESC LIMIT 10',
            [userId]
        );

        // Obtener solicitudes pendientes
        const pendingRecharges = await pool.query(
            'SELECT * FROM comprobante_recarga WHERE id_usuario = $1 AND estado = \'PENDIENTE\' ORDER BY fecha_solicitud DESC',
            [userId]
        );

        res.json({
            saldo: wallet.rows[0].saldo,
            transacciones: transactions.rows,
            recargas_pendientes: pendingRecharges.rows
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al obtener wallet' });
    }
};

const rechargeManual = async (req, res) => {
    try {
        const {
            id_usuario,
            monto,
            metodo,
            comprobante_base64,
            numero_operacion
        } = req.body;

        // Validaciones
        if (!id_usuario || !monto || !metodo) {
            return res.status(400).json({ error: 'Faltan datos requeridos' });
        }

        if (monto < 5 || monto > 500) {
            return res.status(400).json({ error: 'El monto debe estar entre S/ 5 y S/ 500' });
        }

        if (metodo === 'YAPE' && !comprobante_base64) {
            return res.status(400).json({ error: 'Debe subir el comprobante' });
        }

        // Verificar duplicados (mismo comprobante ya usado)
        if (comprobante_base64) {
            const existente = await pool.query(
                'SELECT id FROM solicitudes_recarga WHERE comprobante_base64 = $1',
                [comprobante_base64]
            );

            if (existente.rows.length > 0) {
                return res.status(400).json({ error: 'Este comprobante ya fue usado anteriormente' });
            }
        }

        // Crear solicitud
        const result = await pool.query(
            `INSERT INTO solicitudes_recarga 
       (id_usuario, monto, metodo, comprobante_base64, numero_operacion, estado) 
       VALUES ($1, $2, $3, $4, $5, 'PENDIENTE') 
       RETURNING id, estado, fecha_solicitud`,
            [id_usuario, monto, metodo, comprobante_base64, numero_operacion]
        );

        // Crear notificación de confirmación
        await pool.query(
            `INSERT INTO notificacion (id_usuario, titulo, mensaje, tipo) 
         VALUES ($1, 'Solicitud de Recarga Recibida', $2, 'SYSTEM')`,
            [id_usuario, `Tu solicitud de recarga de S/ ${monto} ha sido recibida y está siendo revisada. Te notificaremos cuando sea aprobada.`]
        );

        res.json({
            id_solicitud: result.rows[0].id,
            estado: 'PENDIENTE',
            fecha_solicitud: result.rows[0].fecha_solicitud,
            mensaje: 'Solicitud enviada. Será revisada en breve.'
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al procesar solicitud de recarga' });
    }
};

const getPendingRecharges = async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT cr.*, u.nombre as usuario_nombre, u.correo as usuario_correo, cr.imagen_comprobante as comprobante_base64
       FROM comprobante_recarga cr
       JOIN usuario u ON cr.id_usuario = u.id
       WHERE cr.estado = 'PENDIENTE'
       ORDER BY cr.fecha_solicitud ASC`
        );

        res.json(result.rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al obtener solicitudes pendientes' });
    }
};

const approveRecharge = async (req, res) => {
    try {
        const { id } = req.params;
        const { id_revisor } = req.body;

        // Obtener datos de la solicitud
        const solicitud = await pool.query(
            'SELECT * FROM comprobante_recarga WHERE id = $1 AND estado = \'PENDIENTE\'',
            [id]
        );

        if (solicitud.rows.length === 0) {
            return res.status(404).json({ error: 'Solicitud no encontrada o ya procesada' });
        }

        const { id_usuario, monto } = solicitud.rows[0];

        // Iniciar transacción
        const client = await pool.connect();
        try {
            await client.query('BEGIN');

            // Actualizar solicitud a APROBADO
            // Note: comprobante_recarga doesn't have id_revisor column in migration, but we can ignore it or add it.
            // For now, let's just update status.
            await client.query(
                `UPDATE comprobante_recarga 
         SET estado = 'APROBADO'
         WHERE id = $1`,
                [id]
            );

            // Actualizar saldo del usuario
            await client.query(
                'UPDATE wallet SET saldo = saldo + $1 WHERE id_usuario = $2',
                [monto, id_usuario]
            );

            // Crear transacción
            await client.query(
                `INSERT INTO transaccion 
         (id_usuario, tipo, monto, descripcion, id_comprobante_recarga) 
         VALUES ($1, 'RECARGA', $2, 'Recarga de billetera aprobada', $3)`,
                [id_usuario, monto, id]
            );

            // Crear notificación
            await client.query(
                `INSERT INTO notificacion (id_usuario, titulo, mensaje, tipo) 
         VALUES ($1, 'Recarga Aprobada', $2, 'SYSTEM')`,
                [id_usuario, `Tu recarga de S/ ${monto} ha sido aprobada exitosamente.`]
            );

            await client.query('COMMIT');

            res.json({ mensaje: 'Recarga aprobada exitosamente', monto });
        } catch (error) {
            await client.query('ROLLBACK');
            throw error;
        } finally {
            client.release();
        }
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al aprobar recarga' });
    }
};

const rejectRecharge = async (req, res) => {
    try {
        const { id } = req.params;
        const { id_revisor, motivo_rechazo } = req.body;

        const result = await pool.query(
            `UPDATE comprobante_recarga 
       SET estado = 'RECHAZADO', observaciones = $1
       WHERE id = $2 AND estado = 'PENDIENTE'
       RETURNING *`,
            [motivo_rechazo || 'Comprobante inválido', id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Solicitud no encontrada o ya procesada' });
        }

        const { id_usuario, monto } = result.rows[0];

        // Crear notificación de rechazo
        await pool.query(
            `INSERT INTO notificacion (id_usuario, titulo, mensaje, tipo) 
         VALUES ($1, 'Recarga Rechazada', $2, 'SYSTEM')`,
            [id_usuario, `Tu solicitud de recarga de S/ ${monto} fue rechazada. Motivo: ${motivo_rechazo || 'Comprobante inválido'}. Por favor, intenta nuevamente con un comprobante válido.`]
        );

        res.json({ mensaje: 'Recarga rechazada', motivo: motivo_rechazo });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al rechazar recarga' });
    }
};

const getMyRecharges = async (req, res) => {
    try {
        const { userId } = req.params;

        const result = await pool.query(
            `SELECT id, monto, metodo, estado, fecha_solicitud, fecha_revision, motivo_rechazo
       FROM solicitudes_recarga
       WHERE id_usuario = $1
       ORDER BY fecha_solicitud DESC
       LIMIT 20`,
            [userId]
        );

        res.json(result.rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al obtener solicitudes' });
    }
};

const rechargeCulqi = async (req, res) => {
    try {
        const { id_usuario, monto, token_culqi, email } = req.body;

        // Validaciones
        if (!id_usuario || !monto || !token_culqi || !email) {
            return res.status(400).json({ error: 'Faltan datos requeridos' });
        }

        if (monto < 5 || monto > 500) {
            return res.status(400).json({ error: 'El monto debe estar entre S/ 5 y S/ 500' });
        }

        // Crear cargo en Culqi
        const culqiResponse = await fetch('https://api.culqi.com/v2/charges', {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${process.env.CULQI_SECRET_KEY}`,
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                amount: Math.round(monto * 100), // Culqi usa céntimos
                currency_code: 'PEN',
                email: email,
                source_id: token_culqi,
            }),
        });

        const culqiData = await culqiResponse.json();

        // Verificar si el pago fue exitoso
        if (culqiData.object === 'error' || !culqiData.id) {
            return res.status(400).json({
                error: 'Pago rechazado',
                mensaje: culqiData.user_message || 'Error en el procesamiento del pago',
            });
        }

        // Pago exitoso - Acreditar saldo inmediatamente
        const client = await pool.connect();
        try {
            await client.query('BEGIN');

            // Crear solicitud APROBADA (para historial)
            const solicitudResult = await client.query(
                `INSERT INTO solicitudes_recarga 
         (id_usuario, monto, metodo, referencia_pago, estado, fecha_revision) 
         VALUES ($1, $2, 'CULQI', $3, 'APROBADO', NOW()) 
         RETURNING id`,
                [id_usuario, monto, culqiData.id]
            );

            const idSolicitud = solicitudResult.rows[0].id;

            // Actualizar saldo
            await client.query(
                'UPDATE wallet SET saldo = saldo + $1 WHERE id_usuario = $2',
                [monto, id_usuario]
            );

            // Crear transacción
            await client.query(
                `INSERT INTO transaccion 
         (id_usuario, tipo, monto, descripcion, id_solicitud_recarga) 
         VALUES ($1, 'RECARGA', $2, 'Recarga con tarjeta (Culqi)', $3)`,
                [id_usuario, monto, idSolicitud]
            );

            // Obtener nuevo saldo
            const walletResult = await client.query(
                'SELECT saldo FROM wallet WHERE id_usuario = $1',
                [id_usuario]
            );

            await client.query('COMMIT');

            res.json({
                exito: true,
                mensaje: '¡Recarga exitosa!',
                nuevo_saldo: walletResult.rows[0].saldo,
                referencia: culqiData.id,
            });
        } catch (error) {
            await client.query('ROLLBACK');
            throw error;
        } finally {
            client.release();
        }
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al procesar recarga automática' });
    }
};

const getPaymentMethods = async (req, res) => {
    try {
        const { userId } = req.params;
        const result = await pool.query(
            'SELECT id, tipo, numero, nombre_titular, es_principal, fecha_creacion FROM payment_method WHERE id_usuario = $1 AND activo = true ORDER BY es_principal DESC, fecha_creacion DESC',
            [userId]
        );
        res.json(result.rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al obtener métodos de pago' });
    }
};

const addPaymentMethod = async (req, res) => {
    try {
        const { userId, tipo, numero, nombreTitular, esPrincipal } = req.body;

        // Si es principal, desmarcar otros
        if (esPrincipal) {
            await pool.query(
                'UPDATE payment_method SET es_principal = false WHERE id_usuario = $1',
                [userId]
            );
        }

        const result = await pool.query(
            'INSERT INTO payment_method (id_usuario, tipo, numero, nombre_titular, es_principal) VALUES ($1, $2, $3, $4, $5) RETURNING *',
            [userId, tipo, numero, nombreTitular, esPrincipal || false]
        );

        res.json(result.rows[0]);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al agregar método de pago' });
    }
};

const deletePaymentMethod = async (req, res) => {
    try {
        const { id } = req.params;
        await pool.query(
            'UPDATE payment_method SET activo = false WHERE id = $1',
            [id]
        );
        res.json({ success: true });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al eliminar método de pago' });
    }
};

const setPrimaryPaymentMethod = async (req, res) => {
    try {
        const { id } = req.params;

        // Obtener userId del método
        const method = await pool.query('SELECT id_usuario FROM payment_method WHERE id = $1', [id]);
        if (method.rows.length === 0) {
            return res.status(404).json({ error: 'Método no encontrado' });
        }

        const userId = method.rows[0].id_usuario;

        // Desmarcar todos
        await pool.query(
            'UPDATE payment_method SET es_principal = false WHERE id_usuario = $1',
            [userId]
        );

        // Marcar el seleccionado
        await pool.query(
            'UPDATE payment_method SET es_principal = true WHERE id = $1',
            [id]
        );

        res.json({ success: true });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al establecer método principal' });
    }
};

const getPaymentAccounts = async (req, res) => {
    try {
        const result = await pool.query(
            'SELECT id, tipo, numero_celular, nombre_titular, qr_code FROM cuenta_recepcion WHERE activo = true'
        );
        res.json(result.rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al obtener cuentas de pago' });
    }
};

const rechargeRequest = async (req, res) => {
    try {
        const { userId, amount, method, imageBase64, operationNumber } = req.body;

        // Validar datos
        if (!userId || !amount || !method || !imageBase64) {
            return res.status(400).json({ error: 'Datos incompletos' });
        }

        if (amount < 10) {
            return res.status(400).json({ error: 'El monto mínimo es S/. 10.00' });
        }

        // Guardar comprobante
        const comprobante = await pool.query(
            'INSERT INTO comprobante_recarga (id_usuario, monto, metodo, numero_operacion, imagen_comprobante, estado, observaciones) VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *',
            [userId, amount, method, operationNumber, imageBase64, 'PENDIENTE', 'Esperando aprobación']
        );

        // No actualizamos saldo ni creamos transacción aquí, eso se hace al aprobar.

        res.json({
            comprobante: comprobante.rows[0],
            message: 'Solicitud enviada. Esperando aprobación del administrador.'
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al procesar recarga' });
    }
};

const rechargeCard = async (req, res) => {
    try {
        const { userId, amount, cardNumber, cardHolder, expiryDate, cvv } = req.body;

        // Validar datos
        if (!userId || !amount || !cardNumber || !cardHolder || !expiryDate || !cvv) {
            return res.status(400).json({ error: 'Datos incompletos' });
        }

        if (amount < 10) {
            return res.status(400).json({ error: 'El monto mínimo es S/. 10.00' });
        }

        // Simular procesamiento de tarjeta
        if (cardNumber.length < 13 || cardNumber.length > 19) {
            return res.status(400).json({ error: 'Número de tarjeta inválido' });
        }

        if (cvv.length < 3 || cvv.length > 4) {
            return res.status(400).json({ error: 'CVV inválido' });
        }

        // Guardar comprobante
        const comprobante = await pool.query(
            'INSERT INTO comprobante_recarga (id_usuario, monto, metodo, numero_operacion, imagen_comprobante, estado, tipo_recarga) VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *',
            [userId, amount, 'TARJETA', `****${cardNumber.slice(-4)}`, 'N/A', 'COMPLETADA', 'TARJETA']
        );

        // Crear transacción
        const transaction = await pool.query(
            'INSERT INTO transaccion (id_usuario, tipo, monto, metodo_pago, descripcion, id_comprobante_recarga) VALUES ($1, $2, $3, $4, $5, $6) RETURNING *',
            [userId, 'RECARGA', amount, 'TARJETA', `Recarga con tarjeta ****${cardNumber.slice(-4)}`, comprobante.rows[0].id]
        );

        // Actualizar saldo automáticamente
        const wallet = await pool.query(
            'UPDATE wallet SET saldo = saldo + $1, fecha_actualizacion = NOW() WHERE id_usuario = $2 RETURNING *',
            [amount, userId]
        );

        res.json({
            comprobante: comprobante.rows[0],
            transaction: transaction.rows[0],
            newBalance: wallet.rows[0].saldo
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al procesar recarga con tarjeta' });
    }
};

const getRechargeHistory = async (req, res) => {
    try {
        const { userId } = req.params;
        const result = await pool.query(
            'SELECT * FROM comprobante_recarga WHERE id_usuario = $1 ORDER BY fecha_solicitud DESC',
            [userId]
        );
        res.json(result.rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al obtener historial' });
    }
};

const requestWithdrawal = async (req, res) => {
    try {
        const { userId, amount, method, numeroDestino } = req.body;

        // Validar datos
        if (!userId || !amount || !method || !numeroDestino) {
            return res.status(400).json({ error: 'Datos incompletos' });
        }

        if (amount < 20) {
            return res.status(400).json({ error: 'El monto mínimo de retiro es S/. 20.00' });
        }

        // Verificar saldo disponible
        const wallet = await pool.query('SELECT saldo FROM wallet WHERE id_usuario = $1', [userId]);

        if (wallet.rows.length === 0) {
            return res.status(404).json({ error: 'Wallet no encontrada' });
        }

        const saldoActual = parseFloat(wallet.rows[0].saldo);

        if (saldoActual < amount) {
            return res.status(400).json({ error: 'Saldo insuficiente' });
        }

        // Crear solicitud de retiro
        const withdrawal = await pool.query(
            'INSERT INTO withdrawal_request (id_usuario, monto, metodo, numero_destino) VALUES ($1, $2, $3, $4) RETURNING *',
            [userId, amount, method, numeroDestino]
        );

        // Descontar saldo inmediatamente
        await pool.query(
            'UPDATE wallet SET saldo = saldo - $1, fecha_actualizacion = NOW() WHERE id_usuario = $2',
            [amount, userId]
        );

        // Crear transacción
        await pool.query(
            'INSERT INTO transaccion (id_usuario, tipo, monto, metodo_pago, descripcion) VALUES ($1, $2, $3, $4, $5)',
            [userId, 'RETIRO', amount, method, `Solicitud de retiro a ${method} ${numeroDestino}`]
        );

        res.json({
            withdrawal: withdrawal.rows[0],
            message: 'Solicitud de retiro creada. Se procesará en 24-48 horas.'
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al procesar solicitud de retiro' });
    }
};

const getWithdrawals = async (req, res) => {
    try {
        const { userId } = req.params;
        const result = await pool.query(
            'SELECT * FROM withdrawal_request WHERE id_usuario = $1 ORDER BY fecha_solicitud DESC',
            [userId]
        );
        res.json(result.rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al obtener historial de retiros' });
    }
};

const getPendingWithdrawals = async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT w.*, u.nombre as usuario_nombre, u.correo as usuario_correo
       FROM withdrawal_request w
       JOIN usuario u ON w.id_usuario = u.id
       WHERE w.estado = 'PENDIENTE'
       ORDER BY w.fecha_solicitud ASC`
        );
        res.json(result.rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al obtener retiros pendientes' });
    }
};

const processWithdrawal = async (req, res) => {
    try {
        const { id } = req.params;
        const { estado, observaciones, adminId } = req.body;

        if (!['PROCESADO', 'RECHAZADO'].includes(estado)) {
            return res.status(400).json({ error: 'Estado inválido' });
        }

        // Si se rechaza, devolver el saldo
        if (estado === 'RECHAZADO') {
            const withdrawal = await pool.query('SELECT id_usuario, monto FROM withdrawal_request WHERE id = $1', [id]);
            if (withdrawal.rows.length > 0) {
                await pool.query(
                    'UPDATE wallet SET saldo = saldo + $1, fecha_actualizacion = NOW() WHERE id_usuario = $2',
                    [withdrawal.rows[0].monto, withdrawal.rows[0].id_usuario]
                );
            }
        }

        const result = await pool.query(
            'UPDATE withdrawal_request SET estado = $1, observaciones = $2, fecha_procesado = NOW(), procesado_por = $3 WHERE id = $4 RETURNING *',
            [estado, observaciones, adminId, id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Solicitud no encontrada' });
        }

        res.json(result.rows[0]);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al procesar retiro' });
    }
};

const getCO2Stats = async (req, res) => {
    try {
        const { userId } = req.params;

        // Obtener viajes completados como conductor
        const conductorTrips = await pool.query(`
      SELECT v.*, COUNT(r.id) as num_pasajeros
      FROM viaje v
      LEFT JOIN reserva r ON v.id = r.id_viaje AND r.estado = 'COMPLETADA'
      WHERE v.id_conductor = $1 AND v.estado = 'COMPLETADO'
      GROUP BY v.id
    `, [userId]);

        // Obtener viajes completados como pasajero
        const pasajeroTrips = await pool.query(`
      SELECT v.*
      FROM viaje v
      JOIN reserva r ON v.id = r.id_viaje
      WHERE r.id_pasajero = $1 AND r.estado = 'COMPLETADA' AND v.estado = 'COMPLETADO'
    `, [userId]);

        let totalCO2Saved = 0;
        let totalKm = 0;
        let totalTrips = 0;

        // Calcular CO2 ahorrado como conductor
        conductorTrips.rows.forEach(trip => {
            const distanceKm = trip.distancia_km || 10;
            const passengers = parseInt(trip.num_pasajeros) || 0;
            const co2Saved = distanceKm * 0.12 * passengers;
            totalCO2Saved += co2Saved;
            totalKm += distanceKm;
            totalTrips++;
        });

        // Calcular CO2 ahorrado como pasajero
        pasajeroTrips.rows.forEach(trip => {
            const distanceKm = trip.distancia_km || 10;
            const co2Saved = distanceKm * 0.12;
            totalCO2Saved += co2Saved;
            totalKm += distanceKm;
            totalTrips++;
        });

        res.json({
            totalCO2SavedKg: Math.round(totalCO2Saved * 100) / 100,
            totalKm: totalKm,
            totalTrips: totalTrips,
            equivalentTrees: Math.round((totalCO2Saved / 21) * 10) / 10
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al obtener estadísticas de CO2' });
    }
};

module.exports = {
    getWallet,
    rechargeManual,
    getPendingRecharges,
    approveRecharge,
    rejectRecharge,
    getMyRecharges,
    rechargeCulqi,
    getPaymentMethods,
    addPaymentMethod,
    deletePaymentMethod,
    setPrimaryPaymentMethod,
    getPaymentAccounts,
    rechargeRequest,
    rechargeCard,
    getRechargeHistory,
    requestWithdrawal,
    getWithdrawals,
    processWithdrawal,
    getPendingWithdrawals,
    getCO2Stats
};
