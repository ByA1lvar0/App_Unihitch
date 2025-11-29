const http = require('http');

const post = (path, data) => {
    return new Promise((resolve, reject) => {
        const options = {
            hostname: 'localhost',
            port: 3000,
            path: path,
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Content-Length': data.length
            }
        };

        const req = http.request(options, (res) => {
            let body = '';
            res.on('data', (chunk) => body += chunk);
            res.on('end', () => resolve({ status: res.statusCode, body: JSON.parse(body || '{}') }));
        });

        req.on('error', (e) => reject(e));
        req.write(data);
        req.end();
    });
};

async function testValidation() {
    console.log('--- Testing Validation ---');

    // 1. Test Invalid Register (Short password, invalid email)
    console.log('\n1. Testing Invalid Register...');
    const invalidRegister = JSON.stringify({
        nombre: 'Test',
        correo: 'not-an-email',
        password: '123', // Too short
        telefono: 'abc' // Not numeric
    });

    try {
        const res1 = await post('/api/register', invalidRegister);
        console.log(`Status: ${res1.status}`);
        if (res1.status === 400 && res1.body.error === 'Datos inválidos') {
            console.log('✅ Register validation passed (Rejected invalid data)');
            console.log('Details:', JSON.stringify(res1.body.details, null, 2));
        } else {
            console.log('❌ Register validation failed');
            console.log('Response:', res1.body);
        }
    } catch (e) {
        console.error('Error connecting to server:', e.message);
    }

    // 2. Test Invalid Login (Empty password)
    console.log('\n2. Testing Invalid Login...');
    const invalidLogin = JSON.stringify({
        correo: 'test@example.com',
        password: ''
    });

    try {
        const res2 = await post('/api/login', invalidLogin);
        console.log(`Status: ${res2.status}`);
        if (res2.status === 400) {
            console.log('✅ Login validation passed (Rejected empty password)');
        } else {
            console.log('❌ Login validation failed');
        }
    } catch (e) {
        console.error('Error connecting to server:', e.message);
    }
}

// Wait a bit for server to start then run
setTimeout(testValidation, 3000);
