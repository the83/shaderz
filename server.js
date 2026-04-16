import http from 'http';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const SHADERS_DIR = path.join(__dirname, 'shaders');
const PORT = 3000;

// SSE clients
const clients = new Set();

// Ensure shaders directory exists
if (!fs.existsSync(SHADERS_DIR)) {
  fs.mkdirSync(SHADERS_DIR);
}

// Watch shaders directory for changes
fs.watch(SHADERS_DIR, (event, filename) => {
  if (!filename || !filename.endsWith('.glsl')) return;
  const msg = `data: ${JSON.stringify({ event, file: filename })}\n\n`;
  for (const res of clients) {
    res.write(msg);
  }
});

const MIME = {
  '.html': 'text/html',
  '.js':   'text/javascript',
  '.css':  'text/css',
  '.glsl': 'text/plain',
};

const server = http.createServer((req, res) => {
  const url = new URL(req.url, `http://localhost:${PORT}`);
  const pathname = url.pathname;

  // SSE watch endpoint
  if (pathname === '/watch') {
    res.writeHead(200, {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      'Connection': 'keep-alive',
      'Access-Control-Allow-Origin': '*',
    });
    res.write(':\n\n'); // comment to establish connection
    clients.add(res);
    req.on('close', () => clients.delete(res));
    return;
  }

  // List shaders
  if (pathname === '/shaders') {
    let files;
    try {
      files = fs.readdirSync(SHADERS_DIR).filter(f => f.endsWith('.glsl')).sort();
    } catch {
      files = [];
    }
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(files));
    return;
  }

  // Serve a shader file
  if (pathname.startsWith('/shaders/')) {
    const name = path.basename(pathname);
    if (!name.endsWith('.glsl')) {
      res.writeHead(400);
      res.end('Bad request');
      return;
    }
    const filePath = path.join(SHADERS_DIR, name);
    if (!filePath.startsWith(SHADERS_DIR)) {
      res.writeHead(403);
      res.end('Forbidden');
      return;
    }
    try {
      const content = fs.readFileSync(filePath, 'utf8');
      res.writeHead(200, { 'Content-Type': 'text/plain' });
      res.end(content);
    } catch {
      res.writeHead(404);
      res.end('Not found');
    }
    return;
  }

  // Serve index.html for /
  if (pathname === '/' || pathname === '/index.html') {
    const filePath = path.join(__dirname, 'index.html');
    try {
      const content = fs.readFileSync(filePath);
      res.writeHead(200, { 'Content-Type': 'text/html' });
      res.end(content);
    } catch {
      res.writeHead(500);
      res.end('Server error: index.html not found');
    }
    return;
  }

  res.writeHead(404);
  res.end('Not found');
});

server.listen(PORT, () => {
  console.log(`shaderz running at http://localhost:${PORT}`);
});
