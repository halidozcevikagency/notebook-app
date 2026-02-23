/**
 * Flutter Web Static File Server + Admin Panel Proxy
 * Flutter build/web çıktısını port 3000'de sunar
 * /admin/* isteklerini PHP admin panel'e (port 8002) proxy'ler
 */
const http = require('http');
const https = require('https');
const fs = require('fs');
const path = require('path');

const FLUTTER_BUILD_DIR = path.join(__dirname, '..', 'notebook_app', 'build', 'web');
const PORT = parseInt(process.env.PORT || '3000');
const ADMIN_PORT = 8002;

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

const EXTERNAL_URL = process.env.REACT_APP_BACKEND_URL;
if (!EXTERNAL_URL) {
  // .env dosyasından oku (supervisor env aktarmayabilir)
  const fs = require('fs');
  try {
    const envContent = fs.readFileSync(path.join(__dirname, '.env'), 'utf-8');
    const match = envContent.match(/^REACT_APP_BACKEND_URL=(.+)$/m);
    if (match) process.env.REACT_APP_BACKEND_URL = match[1].trim();
  } catch (_) {}
}
const EXTERNAL_URL_VAL = process.env.REACT_APP_BACKEND_URL;
if (!EXTERNAL_URL_VAL) {
  console.error('FATAL: REACT_APP_BACKEND_URL env var is not set');
  process.exit(1);
}
// Tek değişken ismi kullan
Object.defineProperty(global, 'EXTERNAL_URL', { value: EXTERNAL_URL_VAL, writable: false });

function proxyToAdmin(req, res) {
  const options = {
    hostname: '127.0.0.1',
    port: ADMIN_PORT,
    path: req.url,
    method: req.method,
    headers: {
      ...req.headers,
      'host': `127.0.0.1:${ADMIN_PORT}`,
      'x-forwarded-host': req.headers['host'] || '',
      'x-forwarded-proto': 'https',
      'x-real-ip': req.socket.remoteAddress || '127.0.0.1',
    },
  };
  // Cloudflare'in eklediği büyük header'ları çıkar (520 hatasını önler)
  delete options.headers['cf-ray'];
  delete options.headers['cf-connecting-ip'];
  delete options.headers['cf-ipcountry'];
  delete options.headers['cf-visitor'];

  const proxy = http.request(options, (proxyRes) => {
    // Location header içindeki yanlış host'u düzelt
    const headers = { ...proxyRes.headers };
    if (headers['location'] && (headers['location'].includes('://localhost') || headers['location'].includes(':8002'))) {
      headers['location'] = headers['location']
        .replace(/https?:\/\/localhost(:\d+)?/, EXTERNAL_URL)
        .replace(/https?:\/\/127\.0\.0\.1(:\d+)?/, EXTERNAL_URL);
    }
    res.writeHead(proxyRes.statusCode, headers);
    proxyRes.pipe(res, { end: true });
  });

  proxy.on('error', (err) => {
    console.error('Admin proxy error:', err.message);
    res.writeHead(502);
    res.end('<h2>Admin panel starting up... Please refresh.</h2>');
  });

  req.pipe(proxy, { end: true });
}

const server = http.createServer((req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-CSRF-TOKEN, X-Requested-With');

  // /admin/* ve Filament/Livewire asset isteklerini PHP artisan serve'e proxy'le
  if (
    req.url === '/admin' ||
    req.url.startsWith('/admin/') ||
    req.url.startsWith('/admin?') ||
    req.url.startsWith('/css/filament/') ||
    req.url.startsWith('/js/filament/') ||
    req.url.startsWith('/livewire/') ||
    req.url.startsWith('/vendor/') ||
    req.url.startsWith('/up')
  ) {
    return proxyToAdmin(req, res);
  }

  let filePath = path.join(FLUTTER_BUILD_DIR, req.url === '/' ? 'index.html' : req.url);
  filePath = filePath.split('?')[0];

  if (!fs.existsSync(filePath)) {
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
  console.log(`Admin panel proxy: /admin -> :${ADMIN_PORT}`);
  console.log(`Serving Flutter from: ${FLUTTER_BUILD_DIR}`);
});
