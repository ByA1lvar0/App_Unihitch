const { Pool } = require('pg');
const bcrypt = require('bcrypt');
require('dotenv').config();

const pool = new Pool({
    user: process.env.DB_USER,
    host: process.env.DB_HOST,
    database: process.env.DB_NAME,
    password: process.env.DB_PASSWORD,
    port: process.env.DB_PORT,
});

async function createAdmin() {
    try {
        const email = 'admin@unihitch.com';
        const password = 'admin123';
        const hashedPassword = await bcrypt.hash(password, 10);

        // Verificar si existe
        const checkUser = await pool.query('SELECT * FROM usuario WHERE correo = $1', [email]);

        if (checkUser.rows.length > 0) {
            // Actualizar existente
            await pool.query(
                'UPDATE usuario SET password = $1, rol = $2, verificado = $3 WHERE correo = $4',
                [hashedPassword, 'ADMIN', true, email]
            );
            console.log('Usuario admin actualizado exitosamente.');
        } else {
            // Crear nuevo
            // Necesitamos un id_universidad válido. Asumiremos 1, o buscaremos uno.
            const uniResult = await pool.query('SELECT id FROM universidad LIMIT 1');
            const idUniversidad = uniResult.rows.length > 0 ? uniResult.rows[0].id : null;

            // Necesitamos un id_carrera válido.
            const carreraResult = await pool.query('SELECT id FROM carrera LIMIT 1');
            const idCarrera = carreraResult.rows.length > 0 ? carreraResult.rows[0].id : null;

            if (!idUniversidad || !idCarrera) {
                console.log("No se encontraron universidades o carreras para asignar al admin. Asegúrate de tener datos en esas tablas.");
                return;
            }

            await pool.query(
                'INSERT INTO usuario (nombre, correo, password, telefono, id_universidad, id_carrera, rol, verificado, codigo_universitario) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)',
                ['Administrador', email, hashedPassword, '999999999', idUniversidad, idCarrera, 'ADMIN', true, 'ADMIN001']
            );
            console.log('Usuario admin creado exitosamente.');
        }

        console.log(`Credenciales:\nCorreo: ${email}\nContraseña: ${password}`);

    } catch (error) {
        console.error('Error al crear admin:', error);
    } finally {
        await pool.end();
    }
}

createAdmin();
