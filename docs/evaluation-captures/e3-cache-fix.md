# E3 source-loading amendment

7 September 2026 · Ready for Joe’s retest. The reported screenshot showed a selected file and ready notice but untouched C placeholder. The E1 app can load IR/CFG without requesting or rendering source. Replaying that script at `/app.js` alongside current HTML reproduces the symptom exactly. This is a controlled reproduction consistent with stale assets; Joe’s actual browser cache was not inspected. The original 71 E3 browser checks disabled caching and missed this upgrade scenario.

The HTML now uses `?v=e3-source-fix-1` for all CSS/JS assets. Preview static responses carry `Cache-Control: no-store` and return current content for conditional reloads. Versioned URLs bypass old cached scripts; the policy prevents reuse in later preview refreshes. The static implementation is `PreviewStaticFiles` in `src/backend/api/app.py`; model queries and source-rendering logic are unchanged. The restarted review server is on port 8000.

- [Controlled reproduction](e3-cache-reproduction.json): two assertions, zero runtime exceptions. [Before screenshot](e3-cache-reproduction.png) visually matches the reported placeholder/ready combination.
- [Fixed browser run](e3-cache-fixed.json): six assertions, zero runtime exceptions, caching enabled. Versioned requests bypass the legacy-script replay; score, binary_search and quick_sort load verified C after a normal reload, and source anchors survive state stepping. [After screenshot](e3-cache-fixed.png) visually inspected. The JSON records current frontend hashes; original E3 captures remain pre-amendment history.
- [Backend tests](e3-cache-tests.txt): 59 pass, including static header and current-body conditional-request checks. JavaScript syntax and both repository whitespace checks pass.

From `irexplorer/`, run `.venv/bin/python -m src.backend.api.server`. Open [the fresh shell URL](http://127.0.0.1:8000/?revision=e3-source-fix-1#/explore), select each file, refresh normally and repeat. This URL also bypasses previously cached HTML. A page already loaded before the fix needs reloading; changing server files cannot replace its running JavaScript.

For the browser regression, start isolated Chrome on port 9225 using the command in [E3 evidence](e3-comparisons.md), then run:

```sh
node scripts/check_e3_cache.mjs
EXPECT_FIXED=1 node scripts/check_e3_cache.mjs
```

The first mode intentionally serves the prior E1 script and an unversioned shell via browser interception; it never edits application files. The second uses the fixed shell, leaving the legacy unversioned-script interceptor in place to prove it is bypassed, then disables interception for an ordinary reload. This uses the existing Git history and Node built-ins. Close the isolated test browser afterwards; keep the review server running.

Instruments and canonical artefacts remain unchanged. No new dependency, E4 work, collection, deployment, commit or push. Physical-keyboard and broader E7 gates remain unchanged. E3 is open pending Joe’s retest.
