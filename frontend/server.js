/**
 * Flutter Web Static File Server
 * Flutter build/web çıktısını port 3000'de sunar
 */
const http = require('http');
const fs = require('fs');
const path = require('path');

const FLUTTER_BUILD_DIR = path.join(__dirname, '..', 'notebook_app', 'build', 'web');
const PORT = parseInt(process.env.PORT || '3000');

const MIME_TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'application/javascript',
  '.css': 'text/css',
  '.json': 'application/json',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.wasm': 'application/wasm',
  '.ttf': 'font/ttf',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2',
  '.map': 'application/json',
};

const server = http.createServer((req, res) => {
  // CORS headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');

  let filePath = path.join(FLUTTER_BUILD_DIR, req.url === '/' ? 'index.html' : req.url);

  // Remove query strings
  filePath = filePath.split('?')[0];

  // Check if file exists
  if (!fs.existsSync(filePath)) {
    // Serve index.html for SPA routing (all unknown routes → index.html)
    filePath = path.join(FLUTTER_BUILD_DIR, 'index.html');
  }

  const ext = path.extname(filePath).toLowerCase();
  const contentType = MIME_TYPES[ext] || 'application/octet-stream';

  fs.readFile(filePath, (err, data) => {
    if (err) {
      res.writeHead(500);
      res.end('Server Error: ' + err.message);
      return;
    }
    res.writeHead(200, { 'Content-Type': contentType });
    res.end(data);
  });
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`Notebook Flutter Web server running on port ${PORT}`);
  console.log(`Serving from: ${FLUTTER_BUILD_DIR}`);
});
