import { createServer } from 'node:http';

createServer((request, response) => {
  if (request.url === '/health') {
    response.writeHead(200, { 'content-type': 'application/json' });
    response.end('{"status":"ok"}');
    return;
  }
  const url = new URL(request.url || '/', 'http://127.0.0.1:8198');
  if (url.pathname === '/api/v1/products/mtd-evidence-rail/verify') {
    const valid = url.searchParams.get('license') === 'fixture-valid-license';
    response.writeHead(200, { 'content-type': 'application/json', 'cache-control': 'no-store' });
    response.end(JSON.stringify({ valid, reason: valid ? 'ok' : 'invalid', expires_at: null }));
    return;
  }
  response.writeHead(404);
  response.end();
}).listen(8198, '127.0.0.1');
