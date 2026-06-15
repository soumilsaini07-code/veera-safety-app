const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const cors = require('cors');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
  cors: { origin: "*", methods: ["GET", "POST"] }
});

app.use(cors());
app.use(express.json());
app.use(express.static('public'));

// Ensure uploads directory exists
const uploadsDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadsDir)) {
    fs.mkdirSync(uploadsDir);
}
app.use('/uploads', express.static('uploads'));

// Multer storage config
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    const userDir = path.join(uploadsDir, req.body.uid || 'unknown');
    if (!fs.existsSync(userDir)) fs.mkdirSync(userDir, { recursive: true });
    cb(null, userDir);
  },
  filename: function (req, file, cb) {
    cb(null, Date.now() + path.extname(file.originalname));
  }
});
const upload = multer({ storage: storage });

const activeAlerts = new Map();

app.post('/api/update', (req, res) => {
  const data = req.body;
  if (data && data.uid) {
    if (activeAlerts.has(data.uid)) {
        // preserve videoUrl if it exists
        const existing = activeAlerts.get(data.uid);
        if (existing.videoUrl && !data.videoUrl) {
            data.videoUrl = existing.videoUrl;
        }
    }
    activeAlerts.set(data.uid, data);
    io.emit('location_update', data);
    res.status(200).json({ success: true });
  } else {
    res.status(400).json({ error: 'Invalid data format' });
  }
});

app.post('/api/upload', upload.single('file'), (req, res) => {
  if (!req.file) {
    return res.status(400).json({ error: 'No file uploaded' });
  }
  
  const uid = req.body.uid;
  if (uid && activeAlerts.has(uid) && req.body.type === 'video') {
     const data = activeAlerts.get(uid);
     data.videoUrl = `/uploads/${uid}/${req.file.filename}`;
     io.emit('location_update', data);
  }

  res.status(200).json({ success: true, path: `/uploads/${req.body.uid || 'unknown'}/${req.file.filename}` });
});

app.get('/api/alerts', (req, res) => {
  res.json(Array.from(activeAlerts.values()));
});

io.on('connection', (socket) => {
  socket.emit('initial_data', Array.from(activeAlerts.values()));
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => console.log(`Veera Server running on port ${PORT}`));
