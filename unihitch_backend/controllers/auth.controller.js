const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const pool = require('../config/db');

const register = async (req, res) => {
    const client = await pool.connect();
    try {
        const { nombre, correo, password, telefono, id_universidad, id_carrera, carrera_nombre, codigo_universitario } = req.body;

        const userExists = await pool.query('SELECT * FROM usuario WHERE correo = $1', [correo]);
        if (userExists.rows.length > 0) {
            client.release();
            return res.status(400).json({ error: 'Este correo ya está registrado' });
        }

        await client.query('BEGIN');

        // Determinar si es agente externo o universitario
        let tipo_usuario = 'AGENTE_EXTERNO';
        let es_agente_externo = true;
        let verificado = false;
        let final_id_carrera = id_carrera;
        let universidad_nombre = null;

        // Si proporciona universidad, verificar dominio
        if (id_universidad) {
            const uniResult = await client.query('SELECT nombre, dominio FROM universidad WHERE id = $1', [id_universidad]);

            if (uniResult.rows.length > 0) {
                universidad_nombre = uniResult.rows[0].nombre;
                const dominios = uniResult.rows[0].dominio; // Ahora es un array
                // Si el correo coincide con alguno de los dominios universitarios
                if (dominios && Array.isArray(dominios) && dominios.some(d => correo.endsWith(d))) {
                    verificado = true;
                    tipo_usuario = 'UNIVERSITARIO';
                    es_agente_externo = false;
                }
            }

            // Manejar carrera por nombre si no hay ID
            if (!final_id_carrera && carrera_nombre) {
                // Buscar si existe la carrera
                const carreraExistente = await client.query(
                    'SELECT id FROM carrera WHERE id_universidad = $1 AND nombre = $2',
                    [id_universidad, carrera_nombre]
                );

                if (carreraExistente.rows.length > 0) {
                    final_id_carrera = carreraExistente.rows[0].id;
                } else {
                    // Crear carrera si no existe
                    const nuevaCarrera = await client.query(
                        'INSERT INTO carrera (id_universidad, nombre, activo) VALUES ($1, $2, true) RETURNING id',
                        [id_universidad, carrera_nombre]
                    );
                    final_id_carrera = nuevaCarrera.rows[0].id;
                }
            }
        } else {
            // Sin universidad = agente externo
            // Verificar que el correo NO sea de ningún dominio universitario registrado
            const allUniversities = await client.query('SELECT dominio FROM universidad WHERE dominio IS NOT NULL');
            const isUniversityEmail = allUniversities.rows.some(uni =>
                uni.dominio && Array.isArray(uni.dominio) && uni.dominio.some(d => correo.endsWith(d))
            );

            if (isUniversityEmail) {
                await client.query('ROLLBACK');
                return res.status(400).json({
                    error: 'Este correo pertenece a una universidad. Por favor selecciona tu universidad al registrarte.'
                });
            }
        }

        const hashedPassword = await bcrypt.hash(password, 10);

        const result = await client.query(
            `INSERT INTO usuario (nombre, correo, password, telefono, id_universidad, id_carrera, codigo_universitario, verificado, tipo_usuario, es_agente_externo) 
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10) 
       RETURNING id, nombre, correo, telefono, rol, verificado, id_universidad, id_carrera, codigo_universitario, tipo_usuario, es_agente_externo`,
            [nombre, correo, hashedPassword, telefono, id_universidad || null, final_id_carrera || null, codigo_universitario || null, verificado, tipo_usuario, es_agente_externo]
        );

        const user = result.rows[0];

        // Note: Wallet is auto-created by database trigger

        // Procesar código de referido si existe
        const { referral_code } = req.body;
        if (referral_code) {
            try {
                // Extraer ID del código (formato: UNIHITCH000001)
                const referrerId = parseInt(referral_code.replace('UNIHITCH', ''));

                if (!isNaN(referrerId)) {
                    // Verificar que el referidor existe
                    const referrerResult = await client.query(
                        'SELECT id FROM usuario WHERE id = $1',
                        [referrerId]
                    );

                    if (referrerResult.rows.length > 0) {
                        // Incrementar contador de referidos del referidor
                        await client.query(
                            'UPDATE usuario SET referral_count = COALESCE(referral_count, 0) + 1 WHERE id = $1',
                            [referrerId]
                        );

                        // Agregar S/. 5 al referidor
                        await client.query(
                            'UPDATE wallet SET saldo = saldo + 5 WHERE id_usuario = $1',
                            [referrerId]
                        );

                        // Agregar S/. 3 al nuevo usuario
                        await client.query(
                            'UPDATE wallet SET saldo = saldo + 3 WHERE id_usuario = $1',
                            [user.id]
                        );
                    }
                }
            } catch (refError) {
                console.error('Error procesando código de referido:', refError);
                // No fallar el registro si hay error en el referido
            }
        }

        await client.query('COMMIT');

        const token = jwt.sign({
            id: user.id,
            rol: user.rol,
            es_agente_externo: user.es_agente_externo,
            id_universidad: user.id_universidad,
            tipo_usuario: user.tipo_usuario
        }, process.env.JWT_SECRET, {
            expiresIn: '7d'
        });

        // Agregar nombre de universidad al objeto usuario
        user.universidad_nombre = universidad_nombre;

        res.json({ user, token });
    } catch (error) {
        await client.query('ROLLBACK');
        console.error(error);
        res.status(500).json({ error: 'Error al registrar usuario' });
    } finally {
        client.release();
    }
};

const login = async (req, res) => {
    try {
        const { correo, password } = req.body;

        // Join con universidad para obtener el nombre
        const result = await pool.query(`
            SELECT u.*, uni.nombre as universidad_nombre 
            FROM usuario u 
            LEFT JOIN universidad uni ON u.id_universidad = uni.id 
            WHERE u.correo = $1
        `, [correo]);

        if (result.rows.length === 0) {
            return res.status(401).json({ error: 'Credenciales incorrectas' });
        }

        const user = result.rows[0];

        const validPassword = await bcrypt.compare(password, user.password);
        if (!validPassword) {
            return res.status(401).json({ error: 'Credenciales incorrectas' });
        }

        const token = jwt.sign({
            id: user.id,
            rol: user.rol,
            es_agente_externo: user.es_agente_externo || false,
            id_universidad: user.id_universidad,
            tipo_usuario: user.tipo_usuario || 'UNIVERSITARIO'
        }, process.env.JWT_SECRET, {
            expiresIn: '7d'
        });

        res.json({
            user: {
                id: user.id,
                nombre: user.nombre,
                correo: user.correo,
                telefono: user.telefono,
                rol: user.rol,
                verificado: user.verificado,
                codigo_universitario: user.codigo_universitario,
                id_universidad: user.id_universidad,
                universidad_nombre: user.universidad_nombre, // Incluir nombre de universidad
                id_carrera: user.id_carrera,
                tipo_usuario: user.tipo_usuario || 'UNIVERSITARIO',
                es_agente_externo: user.es_agente_externo || false
            },
            token
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al iniciar sesión' });
    }
};

module.exports = { register, login };
