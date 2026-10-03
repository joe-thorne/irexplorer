import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import { createServer } from 'node:http';
import { fileURLToPath } from 'node:url';
import test from 'node:test';

const checker = fileURLToPath(new URL('../scripts/check_deployment.mjs', import.meta.url));
const release = {
  version: '0.1.36',
  artefactSha256: 'a'.repeat(64),
  studyVersion: 'study-test',
  contentVersion: 'content-test',
  instrumentVersion: 'instrument-test',
};
const csp = "default-src 'self'; object-src 'none'; base-uri 'self'; frame-ancestors 'none'";

async function runChecker(options = {}) {
  const mode = options.mode ?? 'preview';
  const server = createServer((request, response) => {
    const headers = options.missingHeaders === request.url ? {} : {
      'Content-Security-Policy': csp,
      'X-Content-Type-Options': 'nosniff',
      'Referrer-Policy': 'no-referrer',
      ...(request.url === '/app.js' ? { 'Cache-Control': 'no-store' } : {}),
    };
    if (request.url === '/docs' && options.docsReachable) {
      response.writeHead(200, { ...headers, 'Content-Type': 'text/html' });
      response.end('<html><body>Swagger UI</body></html>');
      return;
    }
    if (request.url === '/docs' || request.url === '/openapi.json') {
      response.writeHead(404, { ...headers, 'Content-Type': 'application/json' });
      response.end(JSON.stringify({ error: { code: 'not_found', message: 'Resource not found.' } }));
      return;
    }
    const body = request.url === '/api/health'
      ? { status: 'ok' }
      : request.url === '/api/release'
        ? release
        : request.url === '/api/study/content'
          ? { ...release, collectionMode: mode, submissionEnabled: true }
          : request.url === '/api/study/submissions'
            ? { error: { code: 'invalid_submission', message: 'Invalid submission.' } }
            : null;
    response.writeHead(body ? (request.method === 'POST' ? 422 : 200) : 200, {
      ...headers,
      ...(request.url === '/app.js' ? { 'Content-Type': 'text/javascript' } : { 'Content-Type': 'application/json' }),
    });
    response.end(request.url === '/app.js' ? '/* app */' : JSON.stringify(body ?? {}));
  });
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  const address = server.address();
  try {
    return await new Promise((resolve, reject) => {
      const child = spawn(process.execPath, [checker, `http://127.0.0.1:${address.port}`, mode, '--service-environment-stdin']);
      let stdout = '';
      let stderr = '';
      child.stdout.setEncoding('utf8').on('data', chunk => { stdout += chunk; });
      child.stderr.setEncoding('utf8').on('data', chunk => { stderr += chunk; });
      child.on('error', reject);
      child.on('close', status => resolve({ status, stdout, stderr }));
      child.stdin.end(`IREXPLORER_COLLECTION_MODE=${mode}\n`);
    });
  } finally {
    await new Promise((resolve, reject) => server.close(error => error ? reject(error) : resolve()));
  }
}

test('deployment checker accepts absent docs and all required security headers', async () => {
  const result = await runChecker();
  assert.equal(result.status, 0, result.stderr);
  assert.match(result.stdout, /\/docs is a controlled 404/);
  assert.match(result.stdout, /\/openapi\.json is a controlled 404/);
});

test('deployment checker requires enabled collection in pilot and live modes', async () => {
  for (const mode of ['pilot', 'live']) {
    const result = await runChecker({ mode });
    assert.equal(result.status, 0, result.stderr);
    assert.match(result.stdout, new RegExp(`/api/study/content \\(${mode},`));
    assert.match(result.stdout, /rejects the non-writing probe with 422 invalid_submission/);
  }
});

test('deployment checker rejects reachable docs', async () => {
  const result = await runChecker({ docsReachable: true });
  assert.notEqual(result.status, 0);
  assert.match(result.stderr, /\/docs: expected packaged 404, got 200/);
});

test('deployment checker rejects missing security headers on study responses', async () => {
  const result = await runChecker({ missingHeaders: '/api/study/content' });
  assert.notEqual(result.status, 0);
  assert.match(result.stderr, /\/api\/study\/content: expected the self-only Content Security Policy/);
});
