// Deployment boundary check. Node 22+; no dependencies or writes.
// Usage: node scripts/check_deployment.mjs https://canonical-host.example

const [originArgument, ...extra] = process.argv.slice(2);
if (!originArgument || extra.length) {
  throw Error('Usage: node scripts/check_deployment.mjs <https://origin>');
}

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

function noStore(response, path) {
  require(response.headers.get('cache-control')?.toLowerCase().split(',').map(value => value.trim()).includes('no-store'),
          `${path}: expected Cache-Control to include no-store`);
}

const checks = [];

const healthResponse = await request('/api/health');
require(healthResponse.status === 200, `/api/health: expected 200, got ${healthResponse.status}`);
const health = await json(healthResponse, '/api/health');
require(health?.status === 'ok', '/api/health: expected {"status":"ok"}');
checks.push('/api/health');

const releaseResponse = await request('/api/release');
require(releaseResponse.status === 200, `/api/release: expected 200, got ${releaseResponse.status}`);
const release = await json(releaseResponse, '/api/release');
require(typeof release?.version === 'string' && release.version.length > 0 && release.version !== 'development',
        '/api/release: expected a packaged, non-development version');
require(typeof release?.artefactSha256 === 'string' && /^[a-f0-9]{64}$/.test(release.artefactSha256),
        '/api/release: expected a 64-character lowercase artefactSha256');
checks.push(`/api/release (${release.version}, ${release.artefactSha256})`);

const appResponse = await request('/app.js');
require(appResponse.status === 200, `/app.js: expected 200, got ${appResponse.status}`);
noStore(appResponse, '/app.js');
checks.push('/app.js Cache-Control: no-store');

const contentResponse = await request('/api/study/content');
require(contentResponse.status === 200, `/api/study/content: expected 200, got ${contentResponse.status}`);
const content = await json(contentResponse, '/api/study/content');
for (const field of ['studyVersion', 'contentVersion', 'instrumentVersion']) {
  require(typeof content?.[field] === 'string' && content[field].length > 0,
          `/api/study/content: expected a non-empty ${field}`);
  require(content[field] === release[field],
          `/api/study/content: ${field} does not match /api/release`);
}
require(content.submissionEnabled === false,
        '/api/study/content: expected submissionEnabled: false while collection is disabled');
checks.push(`/api/study/content (${content.studyVersion}, ${content.contentVersion}, ${content.instrumentVersion})`);

const submissionResponse = await request('/api/study/submissions', {
  method: 'POST',
  headers: {
    Origin: base,
    'Content-Type': 'application/json',
    'Sec-Fetch-Site': 'same-origin',
  },
  body: '{}',
});
require(submissionResponse.status === 503,
        `/api/study/submissions: expected 503 while collection is disabled, got ${submissionResponse.status}`);
const submission = await json(submissionResponse, '/api/study/submissions');
require(submission?.error?.code === 'collection_disabled',
        '/api/study/submissions: expected collection_disabled');
checks.push('/api/study/submissions rejects collection while disabled');

console.log(`Deployment checks passed for ${base}`);
for (const check of checks) console.log(`- ${check}`);
