import http from 'http';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const SHADER_DIRS = ['shaders/sandbox', 'shaders/recurboy'];
const PORT = 3000;

// SSE clients
const clients = new Set();

// Ensure shader directories exist
for (const dir of SHADER_DIRS) {
  const full = path.join(__dirname, dir);
  if (!fs.existsSync(full)) fs.mkdirSync(full, { recursive: true });
}

// Watch both shader directories for changes
for (const dir of SHADER_DIRS) {
  fs.watch(path.join(__dirname, dir), (event, filename) => {
    if (!filename || !filename.endsWith('.glsl')) return;
    const msg = `data: ${JSON.stringify({ event, file: filename, dir })}\n\n`;
    for (const res of clients) {
      res.write(msg);
    }
  });
}

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

  // List shaders (grouped by directory)
  if (pathname === '/shaders') {
    const result = {};
    for (const dir of SHADER_DIRS) {
      const label = path.basename(dir);
      try {
        result[label] = fs.readdirSync(path.join(__dirname, dir))
          .filter(f => f.endsWith('.glsl')).sort();
      } catch {
        result[label] = [];
      }
    }
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(result));
    return;
  }

  // Serve a shader file from either directory
  if (pathname.startsWith('/shaders/')) {
    const parts = pathname.slice('/shaders/'.length).split('/');
    if (parts.length !== 2 || !parts[1].endsWith('.glsl')) {
      res.writeHead(400);
      res.end('Bad request');
      return;
    }
    const filePath = path.join(__dirname, 'shaders', parts[0], parts[1]);
    if (!filePath.startsWith(path.join(__dirname, 'shaders'))) {
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
