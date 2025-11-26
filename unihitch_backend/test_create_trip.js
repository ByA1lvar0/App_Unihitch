const axios = require('axios');

async function testCreateTrip() {
    try {
        // 1. Login to get token and user ID
        console.log('Logging in...');
        const loginResponse = await axios.post('http://localhost:3000/api/login', {
            correo: 'U23270694', // Using the email from the screenshot
            password: 'password123' // I don't know the password, but I can try to register a new user first or use an existing one if I knew the credentials.
        });
        // Wait, I don't have the password. I should register a new user for this test.
    } catch (error) {
        console.log('Login failed (expected if creds are wrong):', error.response?.data || error.message);
    }

    try {
        // Register a temp user
        console.log('Registering temp user...');
        const regResponse = await axios.post('http://localhost:3000/api/register', {
            nombre: 'Test Driver',
            correo: `test_driver_${Date.now()}@utp.edu.pe`,
            password: 'password123',
            telefono: '999888777',
            id_universidad: 1,
            id_carrera: 1
        });

        const { user, token } = regResponse.data;
        console.log('User registered:', user.id);

        // 2. Create Trip
        console.log('Creating trip...');
        const tripData = {
            id_conductor: user.id,
            origen: 'Test Origin',
            destino: 'Test Dest',
            fecha_hora: new Date(Date.now() + 86400000).toISOString(), // Tomorrow
            precio: 5.00,
            asientos_disponibles: 4
        };

        const tripResponse = await axios.post('http://localhost:3000/api/viajes', tripData, {
            headers: { Authorization: `Bearer ${token}` } // Although the endpoint doesn't seem to check token in the code I saw, it's good practice.
        });

        console.log('Trip created successfully:', tripResponse.data);

    } catch (error) {
        console.error('Error creating trip:', error.response?.data || error.message);
    }
}

testCreateTrip();
