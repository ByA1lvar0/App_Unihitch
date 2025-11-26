const http = require('http');
const fs = require('fs');

const data = JSON.stringify({
    id_conductor: 1,
    origen: 'Test Origin',
    destino: 'Test Dest',
    fecha_hora: new Date(Date.now() + 86400000).toISOString(),
    precio: 5.00,
    asientos_disponibles: 4
});

const options = {
    hostname: 'localhost',
    port: 3002,
    path: '/api/viajes',
    method: 'POST',
    headers: {
        'Content-Type': 'application/json',
        'Content-Length': data.length
    }
};

const req = http.request(options, (res) => {
    console.log(`statusCode: ${res.statusCode}`);
    let body = '';
    res.on('data', (d) => { body += d; });
    res.on('end', () => {
        fs.writeFileSync('response.json', body);
        console.log('Response saved to response.json');
    });
});

req.on('error', (error) => {
    console.error(error);
});

req.write(data);
req.end();
