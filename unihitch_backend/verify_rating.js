const http = require('http');

// 1. Create a dummy rating
const postData = JSON.stringify({
    id_viaje: 1, // Assuming trip 1 exists
    id_autor: 1, // Assuming user 1 exists
    id_destinatario: 2, // Assuming user 2 exists
    puntuacion: 5,
    comentario: 'Excelente conductor, muy amable.'
});

const options = {
    hostname: 'localhost',
    port: 3000,
    path: '/api/ratings',
    method: 'POST',
    headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData)
    }
};

const req = http.request(options, (res) => {
    console.log(`STATUS: ${res.statusCode}`);
    res.setEncoding('utf8');
    res.on('data', (chunk) => {
        console.log(`BODY: ${chunk}`);
    });
});

req.on('error', (e) => {
    console.error(`problem with request: ${e.message}`);
});

// Write data to request body
req.write(postData);
req.end();
