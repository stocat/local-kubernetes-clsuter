// Simple local traffic generator
// Requirements: Node.js >= 16

const http = require('http');
const https = require('https');
const { URL } = require('url');
const crypto = require('crypto');

const BASE = process.env.BASE_URL || 'http://localhost:28080';
const HOST_HEADER = process.env.HOST_HEADER || '';
const PATHS = (process.env.PATHS || 'catalog/catalogs,order/orders')
  .split(',').map(s => s.trim()).filter(Boolean);
const INTERVAL_MS = parseInt(process.env.INTERVAL_MS || '1000', 10);
const CONCURRENCY = parseInt(process.env.CONCURRENCY || '1', 10);
const SECRET = process.env.JWT_SECRET || 'replace-with-a-strong-secret-32-bytes-min';
const USER_ID = process.env.USER_ID || 'test';

function b64url(buf) {
  return Buffer.from(buf).toString('base64').replace(/=/g, '')
    .replace(/\+/g, '-').replace(/\//g, '_');
}

function makeJwt(payloadObj) {
  const header = { alg: 'HS256', typ: 'JWT' };
  const h = b64url(JSON.stringify(header));
  const p = b64url(JSON.stringify(payloadObj));
  const data = `${h}.${p}`;
  const sig = b64url(crypto.createHmac('sha256', SECRET).update(data).digest());
  return `${data}.${sig}`;
}

const token = makeJwt({ userId: USER_ID });
const baseUrl = new URL(BASE.endsWith('/') ? BASE.slice(0, -1) : BASE);
const agent = baseUrl.protocol === 'https:' ? new https.Agent({ keepAlive: true }) : new http.Agent({ keepAlive: true });
const client = baseUrl.protocol === 'https:' ? https : http;

function oneRequest(path) {
  return new Promise((resolve) => {
    const fullPath = baseUrl.pathname.replace(/\/$/, '') + '/' + path.replace(/^\//, '');
    const opts = {
      protocol: baseUrl.protocol,
      hostname: baseUrl.hostname,
      port: baseUrl.port || (baseUrl.protocol === 'https:' ? 443 : 80),
      path: fullPath,
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${token}`,
        'User-Agent': 'traffic-gen-local/1.0'
      },
      agent
    };
    if (HOST_HEADER) opts.headers.Host = HOST_HEADER;
    const start = Date.now();
    const req = client.request(opts, (res) => {
      res.resume();
      res.on('end', () => {
        const ms = Date.now() - start;
        process.stdout.write(`[${new Date().toISOString()}] ${opts.path} -> ${res.statusCode} (${ms}ms)\n`);
        resolve(res.statusCode);
      });
    });
    req.on('error', (err) => {
      process.stdout.write(`[${new Date().toISOString()}] ${opts.path} -> ERR ${err.message}\n`);
      resolve(0);
    });
    req.end();
  });
}

async function tick() {
  const tasks = [];
  for (let i = 0; i < CONCURRENCY; i++) {
    for (const p of PATHS) tasks.push(oneRequest(p));
  }
  await Promise.all(tasks);
  setTimeout(tick, INTERVAL_MS);
}

console.log('Traffic generator (local) starting:', { BASE, HOST_HEADER, PATHS, INTERVAL_MS, CONCURRENCY, USER_ID });
tick();

