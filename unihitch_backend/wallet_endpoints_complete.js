// ==================== ENDPOINTS DE WALLET COMPLETOS ====================

// Obtener wallet del usuario
app.get('/api/wallet/:userId', async (req, res) => {
    try {
        const { userId } = req.params;

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

        res.json({
            saldo: wallet.rows[0].saldo,
            transacciones: transactions.rows
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al obtener wallet' });
    }
});

// ==================== MÉTODOS DE PAGO ====================

// Listar métodos de pago del usuario
app.get('/api/payment-methods/:userId', async (req, res) => {
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
});

// Agregar método de pago
app.post('/api/payment-methods', async (req, res) => {
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
});

// Eliminar método de pago
app.delete('/api/payment-methods/:id', async (req, res) => {
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
});

// Establecer método como principal
app.put('/api/payment-methods/:id/set-primary', async (req, res) => {
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
});

// ==================== RECARGAS ====================

// Obtener cuentas de pago disponibles (Yape/Plin de UniHitch)
app.get('/api/payment-accounts', async (req, res) => {
    try {
        const result = await pool.query(
            'SELECT id, tipo, numero_celular, nombre_titular, qr_code FROM cuenta_recepcion WHERE activo = true'
        );
        res.json(result.rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al obtener cuentas de pago' });
    }
});

// Recarga con Yape/Plin (con comprobante)
app.post('/api/wallet/recharge-request', async (req, res) => {
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
            'INSERT INTO comprobante_recarga (id_usuario, monto, metodo, numero_operacion, imagen_comprobante, estado, tipo_recarga) VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *',
            [userId, amount, method, operationNumber, imageBase64, 'COMPLETADA', 'TRANSFERENCIA']
        );

        // Crear transacción
        const transaction = await pool.query(
            'INSERT INTO transaccion (id_usuario, tipo, monto, metodo_pago, descripcion) VALUES ($1, $2, $3, $4, $5) RETURNING *',
            [userId, 'RECARGA', amount, method, `Recarga de saldo vía ${method}`]
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
        res.status(500).json({ error: 'Error al procesar recarga' });
    }
});

// Recarga con tarjeta (simulada)
app.post('/api/wallet/recharge-card', async (req, res) => {
    try {
        const { userId, amount, cardNumber, cardHolder, expiryDate, cvv } = req.body;

        // Validar datos
        if (!userId || !amount || !cardNumber || !cardHolder || !expiryDate || !cvv) {
            return res.status(400).json({ error: 'Datos incompletos' });
        }

        if (amount < 10) {
            return res.status(400).json({ error: 'El monto mínimo es S/. 10.00' });
        }

        // Simular procesamiento de tarjeta (en producción usarías Stripe, Culqi, etc.)
        // Por ahora solo validamos formato básico
        if (cardNumber.length < 13 || cardNumber.length > 19) {
            return res.status(400).json({ error: 'Número de tarjeta inválido' });
        }

        if (cvv.length < 3 || cvv.length > 4) {
            return res.status(400).json({ error: 'CVV inválido' });
        }

        // Guardar comprobante (sin imagen para tarjeta)
        const comprobante = await pool.query(
            'INSERT INTO comprobante_recarga (id_usuario, monto, metodo, numero_operacion, imagen_comprobante, estado, tipo_recarga) VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *',
            [userId, amount, 'TARJETA', `****${cardNumber.slice(-4)}`, 'N/A', 'COMPLETADA', 'TARJETA']
        );

        // Crear transacción
        const transaction = await pool.query(
            'INSERT INTO transaccion (id_usuario, tipo, monto, metodo_pago, descripcion) VALUES ($1, $2, $3, $4, $5) RETURNING *',
            [userId, 'RECARGA', amount, 'TARJETA', `Recarga con tarjeta ****${cardNumber.slice(-4)}`]
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
});

// Obtener historial de recargas
app.get('/api/wallet/recharge-history/:userId', async (req, res) => {
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
});

// ==================== RETIROS ====================

// Solicitar retiro
app.post('/api/wallet/withdrawal-request', async (req, res) => {
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
});

// Obtener historial de retiros
app.get('/api/wallet/withdrawals/:userId', async (req, res) => {
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
});

// Procesar retiro (solo admin)
app.put('/api/wallet/withdrawal/:id/process', async (req, res) => {
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
});

// ==================== ESTADÍSTICAS CO2 ====================

app.get('/api/wallet/co2-stats/:userId', async (req, res) => {
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
});
