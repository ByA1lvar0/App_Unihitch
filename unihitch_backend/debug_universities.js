const pool = require('./config/db');

async function checkUniversities() {
    try {
        console.log('--- Verificando Universidades ---');
        const result = await pool.query('SELECT id, nombre, dominio FROM universidad');
        console.table(result.rows);

        console.log('\n--- Probando Detección ---');
        const testEmails = [
            'alumno@utp.edu.pe',
            'u2012345@alumnos.unp.edu.pe',
            'estudiante@udep.edu.pe'
        ];

        const domainMap = {
            'utp.edu.pe': 'Universidad Tecnológica del Perú',
            'alumnos.unp.edu.pe': 'Universidad Nacional de Piura',
            'ucvvirtual.edu.pe': 'Universidad César Vallejo',
            'udep.edu.pe': 'Universidad de Piura',
            'upn.edu.pe': 'Universidad Privada del Norte',
            'usmp.edu.pe': 'Universidad de San Martín de Porres',
        };

        for (const email of testEmails) {
            const domain = email.split('@')[1];
            console.log(`\nProbando email: ${email} (Dominio: ${domain})`);

            for (const [key, value] of Object.entries(domainMap)) {
                if (domain.includes(key)) {
                    console.log(`Coincide con key: ${key} -> Buscando: ${value}`);
                    const uni = await pool.query(
                        'SELECT id, nombre FROM universidad WHERE nombre ILIKE $1',
                        [`%${value}%`]
                    );
                    if (uni.rows.length > 0) {
                        console.log('✅ ENCONTRADO:', uni.rows[0]);
                    } else {
                        console.log('❌ NO ENCONTRADO en BD');
                    }
                }
            }
        }

    } catch (e) {
        console.error('Error:', e);
    } finally {
        process.exit();
    }
}

checkUniversities();
