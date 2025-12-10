const pool = require('../config/db');

const createReservation = async (req, res) => {
    const client = await pool.connect();

    try {
        const { id_viaje, id_pasajero, metodo_pago } = req.body;

        // Iniciar transacción
        await client.query('BEGIN');

        // Verificar si ya existe reserva
        const existingReserva = await client.query(
            'SELECT * FROM reserva WHERE id_viaje = $1 AND id_pasajero = $2',
            [id_viaje, id_pasajero]
        );

        if (existingReserva.rows.length > 0) {
            await client.query('ROLLBACK');
            return res.status(400).json({ error: 'Ya tienes una reserva para este viaje' });
        }

        // Obtener información del viaje
        const viaje = await client.query(
            'SELECT v.*, v.id_conductor, v.precio, v.asientos_disponibles FROM viaje v WHERE v.id = $1',
            [id_viaje]
        );

        if (viaje.rows.length === 0) {
            await client.query('ROLLBACK');
            return res.status(404).json({ error: 'Viaje no encontrado' });
        }

        const viajeData = viaje.rows[0];
        const precio = parseFloat(viajeData.precio);
        const id_conductor = viajeData.id_conductor;

        if (viajeData.asientos_disponibles <= 0) {
            await client.query('ROLLBACK');
            return res.status(400).json({ error: 'No hay asientos disponibles' });
        }

        // Verificar que el pasajero no sea el conductor
        if (id_pasajero === id_conductor) {
            await client.query('ROLLBACK');
            return res.status(400).json({ error: 'No puedes reservar tu propio viaje' });
        }

        // Lógica según método de pago
        let saldoPasajero = 0;
        const metodoPagoFinal = metodo_pago || 'WALLET';

        if (metodoPagoFinal === 'EFECTIVO') {
            // Permitir pago en efectivo para todos los viajes
            // No descontamos nada del wallet
        } else {
            // PAGO CON WALLET

            // Obtener wallet del pasajero
            let pasajeroWallet = await client.query(
                'SELECT * FROM wallet WHERE id_usuario = $1',
                [id_pasajero]
            );

            // Si no existe wallet, crear una
            if (pasajeroWallet.rows.length === 0) {
                pasajeroWallet = await client.query(
                    'INSERT INTO wallet (id_usuario, saldo) VALUES ($1, 0.00) RETURNING *',
                    [id_pasajero]
                );
            }

            saldoPasajero = parseFloat(pasajeroWallet.rows[0].saldo);

            // Verificar saldo suficiente
            if (saldoPasajero < precio) {
                await client.query('ROLLBACK');
                return res.status(400).json({
                    error: 'Saldo insuficiente',
                    saldo_actual: saldoPasajero,
                    precio_viaje: precio,
                    faltante: precio - saldoPasajero
                });
            }

            // Obtener o crear wallet del conductor
            let conductorWallet = await client.query(
                'SELECT * FROM wallet WHERE id_usuario = $1',
                [id_conductor]
            );

            if (conductorWallet.rows.length === 0) {
                conductorWallet = await client.query(
                    'INSERT INTO wallet (id_usuario, saldo) VALUES ($1, 0.00) RETURNING *',
                    [id_conductor]
                );
            }

            // Descontar dinero del pasajero
            await client.query(
                'UPDATE wallet SET saldo = saldo - $1, fecha_actualizacion = NOW() WHERE id_usuario = $2',
                [precio, id_pasajero]
            );

            // Acreditar dinero al conductor
            await client.query(
                'UPDATE wallet SET saldo = saldo + $1, fecha_actualizacion = NOW() WHERE id_usuario = $2',
                [precio, id_conductor]
            );

            // Crear transacción para el pasajero (débito)
            await client.query(
                'INSERT INTO transaccion (id_usuario, tipo, monto, metodo_pago, descripcion) VALUES ($1, $2, $3, $4, $5)',
                [
                    id_pasajero,
                    'PAGO_VIAJE',
                    precio,
                    'WALLET',
                    `Pago por viaje de ${viajeData.origen} a ${viajeData.destino}`
                ]
            );

            // Crear transacción para el conductor (crédito)
            await client.query(
                'INSERT INTO transaccion (id_usuario, tipo, monto, metodo_pago, descripcion) VALUES ($1, $2, $3, $4, $5)',
                [
                    id_conductor,
                    'INGRESO_VIAJE',
                    precio,
                    'WALLET',
                    `Ingreso por viaje de ${viajeData.origen} a ${viajeData.destino}`
                ]
            );
        }

        // Crear la reserva
        const result = await client.query(
            'INSERT INTO reserva (id_viaje, id_pasajero, estado, metodo_pago) VALUES ($1, $2, $3, $4) RETURNING *',
            [id_viaje, id_pasajero, 'CONFIRMADA', metodoPagoFinal]
        );

        // Reducir asientos disponibles
        await client.query(
            'UPDATE viaje SET asientos_disponibles = asientos_disponibles - 1 WHERE id = $1',
            [id_viaje]
        );

        // Obtener nombre del pasajero para notificación al conductor
        const pasajeroInfo = await client.query(
            'SELECT nombre FROM usuario WHERE id = $1',
            [id_pasajero]
        );
        const nombrePasajero = pasajeroInfo.rows[0]?.nombre || 'Un pasajero';

        // Notificación al pasajero
        await client.query(
            `INSERT INTO notificacion (id_usuario, titulo, mensaje, tipo) 
         VALUES ($1, 'Reserva Confirmada', $2, 'RESERVA')`,
            [id_pasajero, `Tu reserva para el viaje de ${viajeData.origen} a ${viajeData.destino} ha sido confirmada. ${metodoPagoFinal === 'EFECTIVO' ? 'Recuerda llevar efectivo para pagar al conductor.' : 'El pago se ha procesado exitosamente.'}`]
        );

        // Notificación al conductor
        await client.query(
            `INSERT INTO notificacion (id_usuario, titulo, mensaje, tipo) 
         VALUES ($1, 'Nueva Reserva', $2, 'VIAJE')`,
            [id_conductor, `${nombrePasajero} ha reservado un asiento en tu viaje de ${viajeData.origen} a ${viajeData.destino}.`]
        );

        // Confirmar transacción
        await client.query('COMMIT');

        res.json({
            reserva: result.rows[0],
            pago: {
                monto: precio,
                nuevo_saldo_pasajero: metodoPagoFinal === 'EFECTIVO' ? null : saldoPasajero - precio,
                mensaje: metodoPagoFinal === 'EFECTIVO'
                    ? 'Reserva confirmada. Pagarás en efectivo al conductor.'
                    : 'Pago procesado exitosamente'
            }
        });
    } catch (error) {
        await client.query('ROLLBACK');
        console.error(error);
        res.status(500).json({ error: 'Error al crear reserva y procesar pago' });
    } finally {
        client.release();
    }
};

const getMyReservations = async (req, res) => {
    try {
        const { id } = req.params;
        const result = await pool.query(`
      SELECT r.*, v.origen, v.destino, v.fecha_hora, v.precio, u.nombre as conductor_nombre
      FROM reserva r
      JOIN viaje v ON r.id_viaje = v.id
      JOIN usuario u ON v.id_conductor = u.id
      WHERE r.id_pasajero = $1
      ORDER BY v.fecha_hora DESC
    `, [id]);
        res.json(result.rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al obtener reservas' });
    }
};

const cancelReservation = async (req, res) => {
    const client = await pool.connect();

    try {
        const { id } = req.params;
        const { userId } = req.body; // ID del usuario que cancela

        await client.query('BEGIN');

        // Obtener información de la reserva
        const reserva = await client.query(
            `SELECT r.*, v.precio, v.id_conductor, v.origen, v.destino, v.id as id_viaje
       FROM reserva r
       JOIN viaje v ON r.id_viaje = v.id
       WHERE r.id = $1`,
            [id]
        );

        if (reserva.rows.length === 0) {
            await client.query('ROLLBACK');
            return res.status(404).json({ error: 'Reserva no encontrada' });
        }

        const reservaData = reserva.rows[0];
        const precio = parseFloat(reservaData.precio);
        const id_pasajero = reservaData.id_pasajero;
        const id_conductor = reservaData.id_conductor;

        // Verificar que quien cancela sea el pasajero o el conductor
        if (userId !== id_pasajero && userId !== id_conductor) {
            await client.query('ROLLBACK');
            return res.status(403).json({ error: 'No tienes permiso para cancelar esta reserva' });
        }

        // Verificar que la reserva no esté ya cancelada
        if (reservaData.estado === 'CANCELADA') {
            await client.query('ROLLBACK');
            return res.status(400).json({ error: 'Esta reserva ya está cancelada' });
        }

        // Devolver dinero al pasajero
        await client.query(
            'UPDATE wallet SET saldo = saldo + $1, fecha_actualizacion = NOW() WHERE id_usuario = $2',
            [precio, id_pasajero]
        );

        // Descontar dinero del conductor
        await client.query(
            'UPDATE wallet SET saldo = saldo - $1, fecha_actualizacion = NOW() WHERE id_usuario = $2',
            [precio, id_conductor]
        );

        // Crear transacción de devolución para el pasajero
        await client.query(
            'INSERT INTO transaccion (id_usuario, tipo, monto, metodo_pago, descripcion) VALUES ($1, $2, $3, $4, $5)',
            [
                id_pasajero,
                'DEVOLUCION',
                precio,
                'WALLET',
                `Devolución por cancelación de viaje de ${reservaData.origen} a ${reservaData.destino}`
            ]
        );

        // Crear transacción de descuento para el conductor
        await client.query(
            'INSERT INTO transaccion (id_usuario, tipo, monto, metodo_pago, descripcion) VALUES ($1, $2, $3, $4, $5)',
            [
                id_conductor,
                'DEVOLUCION_VIAJE',
                precio,
                'WALLET',
                `Devolución por cancelación de viaje de ${reservaData.origen} a ${reservaData.destino}`
            ]
        );

        // Actualizar estado de la reserva
        await client.query(
            'UPDATE reserva SET estado = $1 WHERE id = $2',
            ['CANCELADA', id]
        );

        // Devolver asiento disponible
        await client.query(
            'UPDATE viaje SET asientos_disponibles = asientos_disponibles + 1 WHERE id = $1',
            [reservaData.id_viaje]
        );

        // Obtener nombres para notificaciones
        const pasajeroInfo = await client.query('SELECT nombre FROM usuario WHERE id = $1', [id_pasajero]);
        const conductorInfo = await client.query('SELECT nombre FROM usuario WHERE id = $1', [id_conductor]);
        const nombrePasajero = pasajeroInfo.rows[0]?.nombre || 'El pasajero';
        const nombreConductor = conductorInfo.rows[0]?.nombre || 'El conductor';

        // Determinar quién canceló
        const canceladoPor = userId === id_pasajero ? 'pasajero' : 'conductor';

        // Notificación al pasajero
        await client.query(
            `INSERT INTO notificacion (id_usuario, titulo, mensaje, tipo) 
         VALUES ($1, 'Reserva Cancelada', $2, 'RESERVA')`,
            [id_pasajero, `Tu reserva para el viaje de ${reservaData.origen} a ${reservaData.destino} ha sido cancelada. ${reservaData.metodo_pago === 'WALLET' ? `Se ha devuelto S/ ${precio} a tu billetera.` : ''}`]
        );

        // Notificación al conductor
        await client.query(
            `INSERT INTO notificacion (id_usuario, titulo, mensaje, tipo) 
         VALUES ($1, 'Reserva Cancelada', $2, 'VIAJE')`,
            [id_conductor, `${nombrePasajero} ha cancelado su reserva para el viaje de ${reservaData.origen} a ${reservaData.destino}. Se ha liberado un asiento.`]
        );

        await client.query('COMMIT');

        res.json({
            mensaje: 'Reserva cancelada exitosamente',
            devolucion: {
                monto: precio,
                pasajero_id: id_pasajero
            }
        });
    } catch (error) {
        await client.query('ROLLBACK');
        console.error(error);
        res.status(500).json({ error: 'Error al cancelar reserva' });
    } finally {
        client.release();
    }
};

module.exports = { createReservation, getMyReservations, cancelReservation };
