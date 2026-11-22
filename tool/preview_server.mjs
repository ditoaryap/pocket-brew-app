#!/usr/bin/env node
/**
 * Pocket Brew — Dual HTTP + HTTPS (TLS 1.3) LAN Preview Server
 *
 * Serves `build/web` on a single port (default 8085) supporting BOTH:
 *   - http://<LAN-IP>:8085  (plain HTTP, zero cert warning)
 *   - https://<LAN-IP>:8085 (TLS 1.3 with auto-generated local SAN cert,
 *                            prevents ERR_SSL_PROTOCOL_ERROR when mobile
 *                            browsers force HTTPS-First / auto-upgrade)
 *
 * Run with Volta Node (already allowed in macOS Firewall):
 *   /Users/ditoaryap/.volta/tools/image/node/24.18.0/bin/node tool/preview_server.mjs
 */

import { execFileSync } from 'node:child_process';
import fs from 'node:fs';
import http from 'node:http';
import https from 'node:https';
import net from 'node:net';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import zlib from 'node:zlib';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const projectRoot = path.resolve(__dirname, '..');

function parseArgs(argv) {
  const opts = {
    port: 8085,
    dir: path.join(projectRoot, 'build', 'web'),
  };
  for (let i = 0; i < argv.length; i++) {
    if ((argv[i] === '--port' || argv[i] === '-p') && argv[i + 1]) {
      opts.port = Number(argv[++i]);
    } else if ((argv[i] === '--dir' || argv[i] === '-d') && argv[i + 1]) {
      opts.dir = path.resolve(argv[++i]);
    }
  }
  return opts;
}

function getLanIps() {
  const nets = os.networkInterfaces();
  const preferred = [];
  const others = [];
  for (const [name, addrs] of Object.entries(nets)) {
    for (const addr of addrs || []) {
      if (addr.family === 'IPv4' && !addr.internal) {
        if (name === 'en0' || name === 'en1') {
          preferred.push(addr.address);
        } else {
          others.push(addr.address);
        }
      }
    }
  }
  return [...new Set([...preferred, ...others])];
}

function ensureLocalCert(lanIps) {
  const certDir = path.join(projectRoot, 'build', 'preview_certs');
  const keyPath = path.join(certDir, 'localhost-lan.key.pem');
  const certPath = path.join(certDir, 'localhost-lan.cert.pem');
  const metaPath = path.join(certDir, 'san.txt');

  const sanParts = [
    ...lanIps.map((ip) => `IP:${ip}`),
    'IP:127.0.0.1',
    'DNS:localhost',
  ];
  const sanValue = sanParts.join(',');

  fs.mkdirSync(certDir, { recursive: true });

  const existingMeta = fs.existsSync(metaPath)
    ? fs.readFileSync(metaPath, 'utf8').trim()
    : '';
  const hasCert = fs.existsSync(keyPath) && fs.existsSync(certPath);

  if (!hasCert || existingMeta !== sanValue) {
    execFileSync(
      'openssl',
      [
        'req',
        '-x509',
        '-newkey',
        'rsa:2048',
        '-nodes',
        '-sha256',
        '-days',
        '365',
        '-keyout',
        keyPath,
        '-out',
        certPath,
        '-subj',
        '/CN=Pocket Brew Local Preview',
        '-addext',
        `subjectAltName=${sanValue}`,
        '-addext',
        'keyUsage=digitalSignature,keyEncipherment',
        '-addext',
        'extendedKeyUsage=serverAuth',
      ],
      { stdio: 'pipe' },
    );
    fs.writeFileSync(metaPath, `${sanValue}\n`, 'utf8');
  }

  return {
    key: fs.readFileSync(keyPath),
    cert: fs.readFileSync(certPath),
  };
}

const MIME_TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'application/javascript; charset=utf-8',
  '.mjs': 'application/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.wasm': 'application/wasm',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.gif': 'image/gif',
  '.webp': 'image/webp',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2',
  '.map': 'application/json; charset=utf-8',
  '.frag': 'text/plain; charset=utf-8',
  '.txt': 'text/plain; charset=utf-8',
};

const COMPRESSIBLE_EXTS = new Set([
  '.html',
  '.js',
  '.mjs',
  '.css',
  '.json',
  '.svg',
  '.wasm',
  '.txt',
]);

const NO_CACHE_EXTS = new Set(['.html', '.js', '.mjs', '.json']);

function createRequestHandler(webDir, protocolLabel) {
  const rootWithSep = webDir.endsWith(path.sep) ? webDir : `${webDir}${path.sep}`;

  return (req, res) => {
    const method = req.method || 'GET';
    if (method !== 'GET' && method !== 'HEAD') {
      res.writeHead(405, { 'Content-Type': 'text/plain; charset=utf-8' });
      res.end('Method Not Allowed');
      return;
    }

    let pathname = '/';
    try {
      const parsed = new URL(req.url || '/', 'http://localhost');
      pathname = decodeURIComponent(parsed.pathname);
    } catch {
      res.writeHead(400, { 'Content-Type': 'text/plain; charset=utf-8' });
      res.end('Bad Request');
      return;
    }

    let relPath = pathname === '/' ? 'index.html' : pathname.replace(/^\/+/, '');
    let filePath = path.resolve(webDir, relPath);

    if (filePath !== webDir && !filePath.startsWith(rootWithSep)) {
      res.writeHead(403, { 'Content-Type': 'text/plain; charset=utf-8' });
      res.end('Forbidden');
      return;
    }

    if (fs.existsSync(filePath) && fs.statSync(filePath).isDirectory()) {
      filePath = path.join(filePath, 'index.html');
    }

    // SPA fallback for extensionless routes (e.g., direct refresh on /methods)
    if (!fs.existsSync(filePath) && !path.extname(relPath)) {
      filePath = path.join(webDir, 'index.html');
    }

    if (!fs.existsSync(filePath) || !fs.statSync(filePath).isFile()) {
      console.log(`[${protocolLabel}] 404 ${method} ${pathname}`);
      res.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' });
      res.end('Not Found');
      return;
    }

    const stat = fs.statSync(filePath);
    const ext = path.extname(filePath).toLowerCase();
    const contentType = MIME_TYPES[ext] || 'application/octet-stream';
    const cacheControl = NO_CACHE_EXTS.has(ext)
      ? 'no-cache, no-store, must-revalidate'
      : 'public, max-age=3600';

    const acceptEncoding = String(req.headers['accept-encoding'] || '');
    const useGzip =
      method === 'GET' &&
      stat.size > 1024 &&
      COMPRESSIBLE_EXTS.has(ext) &&
      acceptEncoding.includes('gzip');

    const headers = {
      'Content-Type': contentType,
      'Cache-Control': cacheControl,
      'X-Content-Type-Options': 'nosniff',
    };

    if (useGzip) {
      headers['Content-Encoding'] = 'gzip';
      headers['Vary'] = 'Accept-Encoding';
    } else {
      headers['Content-Length'] = stat.size;
    }

    res.writeHead(200, headers);
    console.log(`[${protocolLabel}] 200 ${method} ${pathname}`);

    if (method === 'HEAD') {
      res.end();
      return;
    }

    const stream = fs.createReadStream(filePath);
    stream.on('error', () => {
      if (!res.headersSent) res.writeHead(500);
      res.end();
    });

    if (useGzip) {
      stream.pipe(zlib.createGzip({ level: 6 })).pipe(res);
    } else {
      stream.pipe(res);
    }
  };
}

async function main() {
  const { port, dir } = parseArgs(process.argv.slice(2));
  if (!fs.existsSync(path.join(dir, 'index.html'))) {
    console.error(`Error: ${path.join(dir, 'index.html')} not found. Run 'flutter build web' first.`);
    process.exit(1);
  }

  const lanIps = getLanIps();
  const primaryIp = lanIps[0] || '127.0.0.1';
  const tlsCreds = ensureLocalCert(lanIps);

  const httpServer = http.createServer(createRequestHandler(dir, 'HTTP'));
  const httpsServer = https.createServer(tlsCreds, createRequestHandler(dir, 'HTTPS'));

  await Promise.all([
    new Promise((resolve) => httpServer.listen(0, '127.0.0.1', resolve)),
    new Promise((resolve) => httpsServer.listen(0, '127.0.0.1', resolve)),
  ]);

  const httpPort = httpServer.address().port;
  const httpsPort = httpsServer.address().port;

  // Single-port TCP multiplexer: peeks first byte (0x16 = TLS ClientHello)
  const muxServer = net.createServer((client) => {
    client.setNoDelay(true);
    client.on('error', () => {});

    client.once('data', (firstChunk) => {
      const isTls = firstChunk.length > 0 && firstChunk[0] === 0x16;
      const targetPort = isTls ? httpsPort : httpPort;
      const upstream = net.connect(targetPort, '127.0.0.1');
      upstream.setNoDelay(true);

      const cleanup = () => {
        if (!client.destroyed) client.destroy();
        if (!upstream.destroyed) upstream.destroy();
      };

      upstream.on('error', cleanup);
      client.on('error', cleanup);
      upstream.on('close', () => {
        if (!client.destroyed) client.end();
      });
      client.on('close', () => {
        if (!upstream.destroyed) upstream.end();
      });

      upstream.write(firstChunk);
      client.pipe(upstream);
      upstream.pipe(client);
    });
  });

  muxServer.on('error', (err) => {
    console.error('Server error:', err.message);
    process.exit(1);
  });

  muxServer.listen(port, '0.0.0.0', () => {
    console.log(`Pocket Brew Dual HTTP+HTTPS Preview Server running on port ${port}`);
    console.log(`Serving: ${dir}`);
    console.log(`  Mac   : http://localhost:${port}`);
    console.log(`  HP    : http://${primaryIp}:${port}`);
    console.log(`  HTTPS : https://${primaryIp}:${port} (self-signed local cert)`);
  });
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
