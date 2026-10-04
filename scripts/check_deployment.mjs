// Deployment boundary check. Node 22+; no dependencies or writes.
// Usage: node scripts/check_deployment.mjs https://canonical-host.example preview [--expect-closed] --service-environment-stdin

const [originArgument, expectedCollectionMode, ...extra] = process.argv.slice(2);
// Every open mode that starts can submit: the application refuses to start an unfinished pilot or live
// configuration. A closed collection (any mode) is checked only when --expect-closed says it is intended.
const supportedModes = new Set(['local', 'preview', 'pilot', 'live']);
const flags = new Set(extra);
if (!originArgument || !supportedModes.has(expectedCollectionMode) || flags.size !== extra.length ||
    !flags.has('--service-environment-stdin') ||
    [...flags].some(flag => !['--service-environment-stdin', '--expect-closed'].includes(flag))) {
  throw Error('Usage: node scripts/check_deployment.mjs <https://origin> <local|preview|pilot|live> [--expect-closed] --service-environment-stdin');
}
const expectClosed = flags.has('--expect-closed');

const origin = new URL(originArgument);
if (!['http:', 'https:'].includes(origin.protocol) || origin.pathname !== '/' || origin.search || origin.hash) {
  throw Error('Origin must be an http(s) origin without a path, query, or fragment.');
}
const base = origin.origin;

async function request(path, options = {}) {
  let response;
  try {
    response = await fetch(base + path, { signal: AbortSignal.timeout(10_000), ...options });
  } catch (error) {
    throw Error(`${path}: request failed (${error.message})`);
  }
  return response;
}

async function json(response, path) {
  try {
    return await response.json();
  } catch {
    throw Error(`${path}: expected a JSON response`);
  }
}

function require(condition, message) {
  if (!condition) throw Error(message);
}

let serviceEnvironment = '';
for await (const chunk of process.stdin) serviceEnvironment += chunk;
const serviceSettings = new Map(
  serviceEnvironment.trim().split(/\s+/).filter(Boolean).map(setting => setting.split('=', 2)),
);
require(!serviceSettings.has('IREXPLORER_STUDY_MODE'),
        'systemd still sets retired IREXPLORER_STUDY_MODE; application startup rejects it');
require(serviceSettings.get('IREXPLORER_COLLECTION_MODE') === expectedCollectionMode,
        `systemd must set IREXPLORER_COLLECTION_MODE=${expectedCollectionMode}`);
if (expectClosed) {
  require(serviceSettings.get('IREXPLORER_COLLECTION_CLOSED') === '1',
          'systemd must set IREXPLORER_COLLECTION_CLOSED=1 for a closed collection');
} else {
  require([undefined, '0'].includes(serviceSettings.get('IREXPLORER_COLLECTION_CLOSED')),
          'systemd must leave IREXPLORER_COLLECTION_CLOSED unset or 0 for open collection; pass --expect-closed to check a closed one');
}

function noStore(response, path) {
  require(response.headers.get('cache-control')?.toLowerCase().split(',').map(value => value.trim()).includes('no-store'),
          `${path}: expected Cache-Control to include no-store`);
}

function securityHeaders(response, path) {
  require(response.headers.get('content-security-policy') ===
          "default-src 'self'; object-src 'none'; base-uri 'self'; frame-ancestors 'none'",
          `${path}: expected the self-only Content Security Policy with frame-ancestors 'none'`);
  require(response.headers.get('x-content-type-options') === 'nosniff',
          `${path}: expected X-Content-Type-Options: nosniff`);
  require(response.headers.get('referrer-policy') === 'no-referrer',
          `${path}: expected Referrer-Policy: no-referrer`);
}

async function controlledNotFound(path) {
  const response = await request(path);
  require(response.status === 404, `${path}: expected packaged 404, got ${response.status}`);
  securityHeaders(response, path);
  const body = await json(response, path);
  require(body?.error?.code === 'not_found', `${path}: expected controlled not_found response`);
  checks.push(`${path} is a controlled 404`);
}

const checks = [];

const healthResponse = await request('/api/health');
require(healthResponse.status === 200, `/api/health: expected 200, got ${healthResponse.status}`);
securityHeaders(healthResponse, '/api/health');
const health = await json(healthResponse, '/api/health');
require(health?.status === 'ok', '/api/health: expected {"status":"ok"}');
checks.push('/api/health');

const releaseResponse = await request('/api/release');
require(releaseResponse.status === 200, `/api/release: expected 200, got ${releaseResponse.status}`);
securityHeaders(releaseResponse, '/api/release');
const release = await json(releaseResponse, '/api/release');
require(typeof release?.version === 'string' && release.version.length > 0 && release.version !== 'development',
        '/api/release: expected a packaged, non-development version');
require(typeof release?.artefactSha256 === 'string' && /^[a-f0-9]{64}$/.test(release.artefactSha256),
        '/api/release: expected a 64-character lowercase artefactSha256');
checks.push(`/api/release (${release.version}, ${release.artefactSha256})`);

const appResponse = await request('/app.js');
require(appResponse.status === 200, `/app.js: expected 200, got ${appResponse.status}`);
securityHeaders(appResponse, '/app.js');
noStore(appResponse, '/app.js');
checks.push('/app.js Cache-Control: no-store');

await controlledNotFound('/docs');
await controlledNotFound('/openapi.json');

const contentResponse = await request('/api/study/content');
require(contentResponse.status === 200, `/api/study/content: expected 200, got ${contentResponse.status}`);
securityHeaders(contentResponse, '/api/study/content');
const content = await json(contentResponse, '/api/study/content');
require(content?.collectionMode === expectedCollectionMode,
        `/api/study/content: expected collection mode ${expectedCollectionMode}, got ${content?.collectionMode}`);
for (const field of ['studyVersion', 'contentVersion', 'instrumentVersion']) {
  require(typeof content?.[field] === 'string' && content[field].length > 0,
          `/api/study/content: expected a non-empty ${field}`);
  require(content[field] === release[field],
          `/api/study/content: ${field} does not match /api/release`);
}
require(content.submissionEnabled === !expectClosed,
        `/api/study/content: expected submissionEnabled: ${!expectClosed} in ${expectClosed ? 'closed ' : ''}${expectedCollectionMode} collection mode`);
checks.push(`/api/study/content (${expectedCollectionMode}, ${expectClosed ? 'closed, ' : ''}${content.studyVersion}, ${content.contentVersion}, ${content.instrumentVersion})`);

const submissionResponse = await request('/api/study/submissions', {
  method: 'POST',
  headers: {
    Origin: base,
    'Content-Type': 'application/json',
    'Sec-Fetch-Site': 'same-origin',
  },
  body: '{}',
});
securityHeaders(submissionResponse, '/api/study/submissions');
const submission = await json(submissionResponse, '/api/study/submissions');
if (expectClosed) {
  // A closed collection refuses every first delivery before validation, creating and writing no store.
  require(submissionResponse.status === 410,
          `/api/study/submissions: expected 410 in closed ${expectedCollectionMode} collection mode, got ${submissionResponse.status}`);
  require(submission?.error?.code === 'collection_closed', '/api/study/submissions: expected collection_closed');
  noStore(submissionResponse, '/api/study/submissions');
  checks.push('/api/study/submissions refuses the non-writing probe with 410 collection_closed');
} else {
  require(submissionResponse.status === 422,
          `/api/study/submissions: expected 422 in ${expectedCollectionMode} collection mode, got ${submissionResponse.status}`);
  require(submission?.error?.code === 'invalid_submission', '/api/study/submissions: expected invalid_submission');
  checks.push('/api/study/submissions rejects the non-writing probe with 422 invalid_submission');
}

console.log(`Deployment checks passed for ${base}`);
for (const check of checks) console.log(`- ${check}`);
