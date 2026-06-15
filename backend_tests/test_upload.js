const fs = require('fs');
const path = require('path');

// Generate a dummy video file
const dummyVideoPath = path.join(__dirname, 'dummy_chunk.mp4');
fs.writeFileSync(dummyVideoPath, 'this is a fake mp4 chunk data for testing');

async function testUpload() {
    try {
        const boundary = '----WebKitFormBoundary7MA4YWxkTrZu0gW';
        const fileContent = fs.readFileSync(dummyVideoPath);
        
        let body = Buffer.from('--' + boundary + '\r\n');
        body = Buffer.concat([body, Buffer.from('Content-Disposition: form-data; name="uid"\r\n\r\n')]);
        body = Buffer.concat([body, Buffer.from('test_user_777\r\n')]);
        
        body = Buffer.concat([body, Buffer.from('--' + boundary + '\r\n')]);
        body = Buffer.concat([body, Buffer.from('Content-Disposition: form-data; name="type"\r\n\r\n')]);
        body = Buffer.concat([body, Buffer.from('video\r\n')]);

        body = Buffer.concat([body, Buffer.from('--' + boundary + '\r\n')]);
        body = Buffer.concat([body, Buffer.from('Content-Disposition: form-data; name="file"; filename="dummy_chunk.mp4"\r\n')]);
        body = Buffer.concat([body, Buffer.from('Content-Type: video/mp4\r\n\r\n')]);
        body = Buffer.concat([body, fileContent]);
        body = Buffer.concat([body, Buffer.from('\r\n--' + boundary + '--\r\n')]);

        const req = require('http').request('http://3.111.147.106:3000/api/upload', {
            method: 'POST',
            headers: {
                'Content-Type': 'multipart/form-data; boundary=' + boundary,
                'Content-Length': body.length
            }
        }, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                console.log('Upload Status Code:', res.statusCode);
                console.log('Upload Response:', data);
                console.log('Backend Test Complete. The EC2 server successfully received and stored the file chunk!');
            });
        });

        req.on('error', (e) => console.error(e));
        req.write(body);
        req.end();
    } catch(e) {
        console.error("Test failed:", e);
    }
}

// First, simulate a location ping so the user exists in activeAlerts
const postData = JSON.stringify({
    uid: 'test_user_777',
    name: 'Hackathon Tester',
    lat: 28.6139,
    lng: 77.2090,
    battery: 89,
    isSosActive: true,
    timestamp: new Date().toISOString()
});

const req = require('http').request('http://3.111.147.106:3000/api/update', {
    method: 'POST',
    headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData)
    }
}, (res) => {
    let data = '';
    res.on('data', chunk => data += chunk);
    res.on('end', () => {
        console.log('Ping Status:', res.statusCode, data);
        console.log('Now testing 3-second chunk upload simulation...');
        testUpload();
    });
});

req.write(postData);
req.end();
