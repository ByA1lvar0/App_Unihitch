const pool = require('./config/db');

async function fixSchema() {
    try {
        console.log('Attempting to fix database schema...');

        // Add rol column if missing
        await pool.query(`
      ALTER TABLE ubicacion_viaje 
      ADD COLUMN IF NOT EXISTS rol VARCHAR(20);
    `);

        console.log('✅ Column "rol" added (or already existed).');

        // Add fecha_actualizacion column if missing
        await pool.query(`
      ALTER TABLE ubicacion_viaje 
      ADD COLUMN IF NOT EXISTS fecha_actualizacion TIMESTAMP DEFAULT NOW();
    `);

        console.log('✅ Column "fecha_actualizacion" added (or already existed).');

        console.log('Schema fix completed successfully!');
        process.exit(0);
    } catch (error) {
        console.error('Error fixing schema:', error);
        process.exit(1);
    }
}

fixSchema();
