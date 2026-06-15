const http = require('http');
const fs = require('fs');
const path = require('path');

const dummyVideoPath = path.join(__dirname, 'dummy_chunk.mp4');
if (!fs.existsSync(dummyVideoPath)) {
    fs.writeFileSync(dummyVideoPath, 'this is a fake mp4 chunk data for testing');
}

let lat = 28.5355; // South Delhi start
let lng = 77.2410;
const uid = 'victim_priya_101';
const name = 'Priya Sharma';
let battery = 78;
let iteration = 0;

function sendLocationUpdate() {
    lat += 0.0005; // Move slightly North
    lng += 0.0002; // Move slightly East
    if (iteration > 0 && iteration % 5 === 0) battery -= 1; // Drain battery slowly

    const postData = JSON.stringify({
        uid: uid,
        name: name,
        lat: lat,
        lng: lng,
        battery: battery,
        isSosActive: true,
        timestamp: new Date().toISOString()
    });

    const req = http.request('http://3.111.147.106:3000/api/update', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Content-Length': Buffer.byteLength(postData)
        }
    }, (res) => {
        console.log(`[${new Date().toLocaleTimeString()}] Sent Location Update. Battery: ${battery}%. Position: ${lat.toFixed(4)}, ${lng.toFixed(4)}`);
    });
    req.on('error', () => {});
    req.write(postData);
    req.end();
}

function sendVideoUpload() {
    try {
        const boundary = '----WebKitFormBoundary7MA4YWxkTrZu0gW';
        const fileContent = fs.readFileSync(dummyVideoPath);
        
        let body = Buffer.from('--' + boundary + '\r\n');
        body = Buffer.concat([body, Buffer.from('Content-Disposition: form-data; name="uid"\r\n\r\n')]);
        body = Buffer.concat([body, Buffer.from(uid + '\r\n')]);
        
        body = Buffer.concat([body, Buffer.from('--' + boundary + '\r\n')]);
        body = Buffer.concat([body, Buffer.from('Content-Disposition: form-data; name="type"\r\n\r\n')]);
        body = Buffer.concat([body, Buffer.from('video\r\n')]);

        body = Buffer.concat([body, Buffer.from('--' + boundary + '\r\n')]);
        body = Buffer.concat([body, Buffer.from('Content-Disposition: form-data; name="file"; filename="dummy_chunk.mp4"\r\n')]);
        body = Buffer.concat([body, Buffer.from('Content-Type: video/mp4\r\n\r\n')]);
        body = Buffer.concat([body, fileContent]);
        body = Buffer.concat([body, Buffer.from('\r\n--' + boundary + '--\r\n')]);

        const req = http.request('http://3.111.147.106:3000/api/upload', {
            method: 'POST',
            headers: {
                'Content-Type': 'multipart/form-data; boundary=' + boundary,
                'Content-Length': body.length
            }
        }, (res) => {
            console.log(`[${new Date().toLocaleTimeString()}] Uploaded 3-second Video Chunk.`);
        });
        req.on('error', () => {});
        req.write(body);
        req.end();
    } catch(e) {}
}

console.log(`Starting Live Tracking Simulation for '${name}'...`);

setInterval(() => {
    iteration++;
    sendLocationUpdate();
    sendVideoUpload();
}, 3000); // exactly matching the 3-second app cycle

// Send initial immediately
sendLocationUpdate();
sendVideoUpload();
