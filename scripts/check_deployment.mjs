// Deployment boundary check. Node 22+; no dependencies or writes.
// Usage: node scripts/check_deployment.mjs https://canonical-host.example preview --service-environment-stdin

const [originArgument, expectedCollectionMode, ...extra] = process.argv.slice(2);
const enabledModes = new Set(['local', 'preview']);
const supportedModes = new Set([...enabledModes, 'pilot', 'live']);
if (!originArgument || !supportedModes.has(expectedCollectionMode) || extra.length !== 1 ||
    extra[0] !== '--service-environment-stdin') {
  throw Error('Usage: node scripts/check_deployment.mjs <https://origin> <local|preview|pilot|live> --service-environment-stdin');
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

let serviceEnvironment = '';
for await (const chunk of process.stdin) serviceEnvironment += chunk;
const serviceSettings = new Map(
  serviceEnvironment.trim().split(/\s+/).filter(Boolean).map(setting => setting.split('=', 2)),
);
require(!serviceSettings.has('IREXPLORER_STUDY_MODE'),
        'systemd still sets retired IREXPLORER_STUDY_MODE; application startup rejects it');
require(serviceSettings.get('IREXPLORER_COLLECTION_MODE') === expectedCollectionMode,
        `systemd must set IREXPLORER_COLLECTION_MODE=${expectedCollectionMode}`);

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
require(content?.collectionMode === expectedCollectionMode,
        `/api/study/content: expected collection mode ${expectedCollectionMode}, got ${content?.collectionMode}`);
for (const field of ['studyVersion', 'contentVersion', 'instrumentVersion']) {
  require(typeof content?.[field] === 'string' && content[field].length > 0,
          `/api/study/content: expected a non-empty ${field}`);
  require(content[field] === release[field],
          `/api/study/content: ${field} does not match /api/release`);
}
const expectedSubmissionEnabled = enabledModes.has(expectedCollectionMode);
require(content.submissionEnabled === expectedSubmissionEnabled,
        `/api/study/content: expected submissionEnabled: ${expectedSubmissionEnabled} in ${expectedCollectionMode} collection mode`);
checks.push(`/api/study/content (${expectedCollectionMode}, ${content.studyVersion}, ${content.contentVersion}, ${content.instrumentVersion})`);

const submissionResponse = await request('/api/study/submissions', {
  method: 'POST',
  headers: {
    Origin: base,
    'Content-Type': 'application/json',
    'Sec-Fetch-Site': 'same-origin',
  },
  body: '{}',
});
const submission = await json(submissionResponse, '/api/study/submissions');
const expectedSubmissionStatus = expectedSubmissionEnabled ? 422 : 503;
const expectedSubmissionCode = expectedSubmissionEnabled ? 'invalid_submission' : 'collection_disabled';
require(submissionResponse.status === expectedSubmissionStatus,
        `/api/study/submissions: expected ${expectedSubmissionStatus} in ${expectedCollectionMode} collection mode, got ${submissionResponse.status}`);
require(submission?.error?.code === expectedSubmissionCode,
        `/api/study/submissions: expected ${expectedSubmissionCode}`);
checks.push(`/api/study/submissions rejects the non-writing probe with ${expectedSubmissionStatus} ${expectedSubmissionCode}`);

console.log(`Deployment checks passed for ${base}`);
for (const check of checks) console.log(`- ${check}`);
