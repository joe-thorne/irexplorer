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

// A stub service, open by default; `closed` models IREXPLORER_COLLECTION_CLOSED=1, and the checker
// expects closure (--expect-closed) exactly when the stub is closed unless `expectClosed` says otherwise.
async function runChecker(options = {}) {
  const mode = options.mode ?? 'preview';
  const closed = options.closed ?? false;
  const refusesClosed = options.refusesClosed ?? closed;
  const expectClosed = options.expectClosed ?? closed;
  const flags = options.flags ?? (expectClosed ? ['--expect-closed', '--service-environment-stdin'] : ['--service-environment-stdin']);
  const environment = options.environment ?? `IREXPLORER_COLLECTION_MODE=${mode}\n${closed ? 'IREXPLORER_COLLECTION_CLOSED=1\n' : ''}`;
  const server = createServer((request, response) => {
    const headers = options.missingHeaders === request.url ? {} : {
      'Content-Security-Policy': csp,
      'X-Content-Type-Options': 'nosniff',
      'Referrer-Policy': 'no-referrer',
      ...(['/app.js', '/api/study/submissions'].includes(request.url) ? { 'Cache-Control': 'no-store' } : {}),
    };
    if (options.missingHeader?.[0] === request.url) delete headers[options.missingHeader[1]];
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
          ? { ...release, collectionMode: mode, submissionEnabled: options.submissionEnabled ?? !closed }
          : request.url === '/api/study/submissions'
            ? refusesClosed
              ? { error: { code: 'collection_closed', message: 'Study collection has closed. These answers were not saved.' } }
              : { error: { code: 'invalid_submission', message: 'Invalid submission.' } }
            : null;
    response.writeHead(body ? (request.method === 'POST' ? (refusesClosed ? 410 : 422) : 200) : 200, {
      ...headers,
      ...(request.url === '/app.js' ? { 'Content-Type': 'text/javascript' } : { 'Content-Type': 'application/json' }),
    });
    response.end(request.url === '/app.js' ? '/* app */' : JSON.stringify(body ?? {}));
  });
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  const address = server.address();
  try {
    return await new Promise((resolve, reject) => {
      const origin = `http://127.0.0.1:${address.port}`;
      const child = spawn(process.execPath, [checker, origin, mode, ...flags]);
      let stdout = '';
      let stderr = '';
      child.stdout.setEncoding('utf8').on('data', chunk => { stdout += chunk; });
      child.stderr.setEncoding('utf8').on('data', chunk => { stderr += chunk; });
      child.on('error', reject);
      child.on('close', status => resolve({ status, stdout, stderr, origin }));
      child.stdin.end(environment);
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

test('deployment checker confirms closed collection in every mode when closure is expected', async () => {
  for (const mode of ['local', 'preview', 'pilot', 'live']) {
    const result = await runChecker({ mode, closed: true });
    assert.equal(result.status, 0, result.stderr);
    const lines = result.stdout.trim().split('\n');
    assert.equal(lines[0], `Deployment checks passed for ${result.origin}`);
    assert.ok(lines.includes(`- /api/study/content (${mode}, closed, study-test, content-test, instrument-test)`), result.stdout);
    assert.ok(lines.includes('- /api/study/submissions refuses the non-writing probe with 410 collection_closed'), result.stdout);
  }
  // The two flags may appear in either order after the mode.
  const reordered = await runChecker({ closed: true, flags: ['--service-environment-stdin', '--expect-closed'] });
  assert.equal(reordered.status, 0, reordered.stderr);
  const open = await runChecker();
  assert.equal(open.status, 0, open.stderr);
  assert.ok(open.stdout.split('\n').includes('- /api/study/content (preview, study-test, content-test, instrument-test)'), open.stdout);
  assert.doesNotMatch(open.stdout, /closed/);
});

test('deployment checker rejects a closed expectation that the service does not meet', async () => {
  for (const [options, failure] of [
    [{ submissionEnabled: true }, /\/api\/study\/content: expected submissionEnabled: false/],
    [{ refusesClosed: false }, /\/api\/study\/submissions: expected 410/],
    [{ environment: 'IREXPLORER_COLLECTION_MODE=preview\n' }, /systemd must set IREXPLORER_COLLECTION_CLOSED=1/],
    [{ environment: 'IREXPLORER_COLLECTION_MODE=preview\nIREXPLORER_COLLECTION_CLOSED=0\n' }, /systemd must set IREXPLORER_COLLECTION_CLOSED=1/],
    [{ missingHeader: ['/api/study/submissions', 'Referrer-Policy'] }, /\/api\/study\/submissions: expected Referrer-Policy: no-referrer/],
    [{ missingHeader: ['/api/study/submissions', 'Cache-Control'] }, /\/api\/study\/submissions: expected Cache-Control to include no-store/],
  ]) {
    const result = await runChecker({ closed: true, ...options });
    assert.notEqual(result.status, 0, JSON.stringify(options));
    assert.match(result.stderr, failure);
  }
});

test('deployment checker rejects closure when open collection is expected', async () => {
  const configured = await runChecker({ environment: 'IREXPLORER_COLLECTION_MODE=preview\nIREXPLORER_COLLECTION_CLOSED=1\n' });
  assert.notEqual(configured.status, 0);
  assert.match(configured.stderr, /systemd must leave IREXPLORER_COLLECTION_CLOSED unset or 0 for open collection; pass --expect-closed/);
  const closed = await runChecker({ closed: true, expectClosed: false, environment: 'IREXPLORER_COLLECTION_MODE=preview\n' });
  assert.notEqual(closed.status, 0);
  assert.match(closed.stderr, /\/api\/study\/content: expected submissionEnabled: true/);
});
