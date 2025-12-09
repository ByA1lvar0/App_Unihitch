const pool = require('./config/db');
const jwt = require('jsonwebtoken');
require('dotenv').config();

async function runDiagnostics() {
    console.log('='.repeat(60));
    console.log('DIAGNÓSTICO COMPLETO DEL SISTEMA UNIHITCH');
    console.log('='.repeat(60));
    console.log('');

    try {
        // 1. Verificar conexión a base de datos
        console.log('1️⃣  VERIFICANDO CONEXIÓN A BASE DE DATOS...');
        const dbTest = await pool.query('SELECT NOW()');
        console.log('   ✅ Base de datos conectada:', dbTest.rows[0].now);
        console.log('');

        // 2. Verificar JWT_SECRET
        console.log('2️⃣  VERIFICANDO JWT_SECRET...');
        if (process.env.JWT_SECRET) {
            console.log('   ✅ JWT_SECRET configurado:', process.env.JWT_SECRET.substring(0, 4) + '***');

            // Probar generación de token
            const testToken = jwt.sign({ id: 1, rol: 'USUARIO' }, process.env.JWT_SECRET, { expiresIn: '7d' });
            const verified = jwt.verify(testToken, process.env.JWT_SECRET);
            console.log('   ✅ Token generado y verificado correctamente');
        } else {
            console.log('   ❌ JWT_SECRET NO CONFIGURADO');
        }
        console.log('');

        // 3. Verificar usuario de prueba (Adriana Elias)
        console.log('3️⃣  VERIFICANDO USUARIO DE PRUEBA...');
        const userRes = await pool.query("SELECT * FROM usuario WHERE nombre ILIKE '%Adriana%' LIMIT 1");
        if (userRes.rows.length > 0) {
            const user = userRes.rows[0];
            console.log('   ✅ Usuario encontrado:');
            console.log('      ID:', user.id);
            console.log('      Nombre:', user.nombre);
            console.log('      Correo:', user.correo);
            console.log('      Es Agente Externo:', user.es_agente_externo);
            console.log('      Verificado:', user.verificado);

            // 4. Verificar documentos del usuario
            console.log('');
            console.log('4️⃣  VERIFICANDO DOCUMENTOS DEL USUARIO...');
            const docsRes = await pool.query(
                'SELECT tipo_documento, estado, fecha_subida FROM documentos_conductor WHERE id_conductor = $1',
                [user.id]
            );

            if (docsRes.rows.length > 0) {
                console.log('   📄 Documentos encontrados:');
                docsRes.rows.forEach(doc => {
                    const icon = doc.estado === 'APROBADO' ? '✅' : doc.estado === 'PENDIENTE' ? '⏳' : '❌';
                    console.log(`      ${icon} ${doc.tipo_documento}: ${doc.estado}`);
                });
            } else {
                console.log('   ⚠️  No hay documentos subidos');
            }

            // Calcular si puede ofrecer viajes
            const esAgenteExterno = user.es_agente_externo || false;
            const documentosRequeridos = esAgenteExterno
                ? ['SOAT', 'LICENCIA', 'DNI', 'TARJETA_MANTENIMIENTO', 'FOTO_PERFIL']
                : ['SOAT', 'LICENCIA', 'FOTO_PERFIL'];

            const documentos = {};
            docsRes.rows.forEach(doc => {
                documentos[doc.tipo_documento] = doc.estado;
            });

            const todosAprobados = documentosRequeridos.every(doc => documentos[doc] === 'APROBADO');
            const faltantes = documentosRequeridos.filter(doc => !documentos[doc] || documentos[doc] !== 'APROBADO');

            console.log('');
            console.log('   📋 Documentos requeridos:', documentosRequeridos.join(', '));
            console.log('   📋 Documentos faltantes:', faltantes.length > 0 ? faltantes.join(', ') : 'Ninguno');
            console.log('   🚗 Puede ofrecer viajes:', todosAprobados ? '✅ SÍ' : '❌ NO');

        } else {
            console.log('   ⚠️  Usuario no encontrado');
        }
        console.log('');

        // 5. Verificar chats
        console.log('5️⃣  VERIFICANDO CHATS...');
        const chatsRes = await pool.query('SELECT COUNT(*) as total FROM chat');
        console.log('   💬 Total de chats:', chatsRes.rows[0].total);

        const messagesRes = await pool.query('SELECT COUNT(*) as total FROM mensaje');
        console.log('   📨 Total de mensajes:', messagesRes.rows[0].total);
        console.log('');

        // 6. Verificar viajes
        console.log('6️⃣  VERIFICANDO VIAJES...');
        const tripsRes = await pool.query("SELECT COUNT(*) as total FROM viaje WHERE estado = 'DISPONIBLE'");
        console.log('   🚗 Viajes disponibles:', tripsRes.rows[0].total);
        console.log('');

        // 7. Verificar middleware files
        console.log('7️⃣  VERIFICANDO ARCHIVOS DE MIDDLEWARE...');
        const fs = require('fs');
        const middlewareFiles = [
            './middleware/auth.middleware.js',
            './middleware/chat-validation.middleware.js',
            './middleware/driver-validation.middleware.js',
            './middleware/external-user.middleware.js'
        ];

        middlewareFiles.forEach(file => {
            if (fs.existsSync(file)) {
                console.log(`   ✅ ${file}`);
            } else {
                console.log(`   ❌ ${file} NO ENCONTRADO`);
            }
        });
        console.log('');

        // 8. Verificar rutas protegidas
        console.log('8️⃣  VERIFICANDO RUTAS PROTEGIDAS...');
        const routeFiles = [
            './routes/chat.routes.js',
            './routes/trip.routes.js',
            './routes/driver.routes.js',
            './routes/user.routes.js'
        ];

        routeFiles.forEach(file => {
            if (fs.existsSync(file)) {
                const content = fs.readFileSync(file, 'utf8');
                const hasAuth = content.includes('authMiddleware');
                console.log(`   ${hasAuth ? '✅' : '❌'} ${file} ${hasAuth ? '(protegido)' : '(SIN PROTECCIÓN)'}`);
            }
        });
        console.log('');

        console.log('='.repeat(60));
        console.log('DIAGNÓSTICO COMPLETADO');
        console.log('='.repeat(60));

    } catch (error) {
        console.error('❌ ERROR EN DIAGNÓSTICO:', error);
    } finally {
        pool.end();
    }
}

runDiagnostics();
