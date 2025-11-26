// ==================== RUTAS DE VERIFICACIÓN DE EMAIL ====================
const emailService = require('./services/email_service');

// Enviar código de verificación
app.post('/api/auth/send-verification-code', async (req, res) => {
    try {
        const { email, userId } = req.body;

        // Generar código de 6 dígitos
        const code = emailService.generateVerificationCode();

        // Guardar código en base de datos
        await pool.query(
            `INSERT INTO codigos_verificacion_email (id_usuario, codigo, email)
       VALUES ($1, $2, $3)`,
            [userId, code, email]
        );

        // Obtener nombre del usuario
        const userResult = await pool.query('SELECT nombre FROM usuario WHERE id = $1', [userId]);
        const userName = userResult.rows[0]?.nombre || 'Usuario';

        // Enviar email
        await emailService.sendVerificationEmail(email, code, userName);

        res.json({
            success: true,
            message: 'Código enviado a tu email',
            expiresIn: '15 minutos'
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al enviar código de verificación' });
    }
});

// Verificar código ingresado
app.post('/api/auth/verify-email-code', async (req, res) => {
    try {
        const { userId, code } = req.body;

        // Buscar código válido (no usado y no expirado)
        const result = await pool.query(
            `SELECT * FROM codigos_verificacion_email
       WHERE id_usuario = $1 
       AND codigo = $2 
       AND usado = FALSE 
       AND fecha_expiracion > NOW()
       ORDER BY fecha_creacion DESC
       LIMIT 1`,
            [userId, code]
        );

        if (result.rows.length === 0) {
            // Registrar intento fallido
            await pool.query(
                'INSERT INTO intentos_verificacion_email (id_usuario, codigo_ingresado, exitoso) VALUES ($1, $2, FALSE)',
                [userId, code]
            );

            // Incrementar contador de intentos fallidos
            await pool.query(
                'UPDATE codigos_verificacion_email SET intentos_fallidos = intentos_fallidos + 1 WHERE id_usuario = $1 AND codigo = $2',
                [userId, code]
            );

            return res.status(400).json({ error: 'Código inválido o expirado' });
        }

        const codigoData = result.rows[0];

        // Verificar límite de intentos fallidos (prevenir fuerza bruta)
        if (codigoData.intentos_fallidos >= 5) {
            return res.status(429).json({ error: 'Demasiados intentos. Solicita un nuevo código.' });
        }

        // Marcar código como usado
        await pool.query(
            'UPDATE codigos_verificacion_email SET usado = TRUE, fecha_uso = NOW() WHERE id = $1',
            [codigoData.id]
        );

        // Marcar email como verificado en usuario
        await pool.query(
            'UPDATE usuario SET email_verificado = TRUE, fecha_verificacion_email = NOW() WHERE id = $1',
            [userId]
        );

        // Registrar intento exitoso
        await pool.query(
            'INSERT INTO intentos_verificacion_email (id_usuario, codigo_ingresado, exitoso) VALUES ($1, $2, TRUE)',
            [userId, code]
        );

        res.json({
            success: true,
            message: '¡Email verificado exitosamente!'
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al verificar código' });
    }
});

// Reenviar código de verificación
app.post('/api/auth/resend-verification-code', async (req, res) => {
    try {
        const { userId } = req.body;

        // Obtener datos del usuario
        const userResult = await pool.query(
            'SELECT email, nombre, email_verificado FROM usuario WHERE id = $1',
            [userId]
        );

        if (userResult.rows.length === 0) {
            return res.status(404).json({ error: 'Usuario no encontrado' });
        }

        const { email, nombre, email_verificado } = userResult.rows[0];

        if (email_verificado) {
            return res.status(400).json({ error: 'Email ya verificado' });
        }

        // Marcar códigos anteriores como usados (invalidar)
        await pool.query(
            'UPDATE codigos_verificacion_email SET usado = TRUE WHERE id_usuario = $1 AND usado = FALSE',
            [userId]
        );

        // Generar nuevo código
        const code = emailService.generateVerificationCode();

        // Guardar nuevo código
        await pool.query(
            'INSERT INTO codigos_verificacion_email (id_usuario, codigo, email) VALUES ($1, $2, $3)',
            [userId, code, email]
        );

        // Enviar email
        await emailService.sendVerificationEmail(email, code, nombre);

        res.json({
            success: true,
            message: 'Código reenviado a tu email'
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al reenviar código' });
    }
});

// Verificar si email está verificado (útil para UI)
app.get('/api/auth/email-status/:userId', async (req, res) => {
    try {
        const { userId } = req.params;

        const result = await pool.query(
            'SELECT email_verificado, fecha_verificacion_email FROM usuario WHERE id = $1',
            [userId]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Usuario no encontrado' });
        }

        res.json({
            verified: result.rows[0].email_verificado,
            verifiedAt: result.rows[0].fecha_verificacion_email
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al verificar estado' });
    }
});
