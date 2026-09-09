"""Fingerprint the actual image inputs, including uncommitted source changes."""
import hashlib
import json
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
from src.backend.toolchain.integrity import verify_curated_snapshot


def digest_files(paths):
    records = [(p.relative_to(ROOT).as_posix(), hashlib.sha256(p.read_bytes()).hexdigest())
               for p in sorted(paths) if p.is_file() and '__pycache__' not in p.parts]
    digest = hashlib.sha256(''.join(f'{name}\0{digest}\n' for name, digest in records).encode()).hexdigest()
    return digest, dict(records)


def build(version):
    if not re.fullmatch(r'\d+\.\d+\.\d+(?:-[a-zA-Z0-9.-]+)?', version):
        raise ValueError('Use a semantic application version, for example 0.1.0')
    verify_curated_snapshot()
    paths = [p for directory in ('src', 'examples', 'artefacts') for p in (ROOT / directory).rglob('*')]
    paths += [ROOT / p for p in ('Dockerfile', 'docker-compose.yml', '.dockerignore',
                                'scripts/build_release.py', 'docs/curated-artefacts.sha256')]
    digest, files = digest_files(paths)
    pin = dict(line.split('=', 1) for line in (ROOT / 'docs/curated-artefacts.sha256').read_text().splitlines()
               if line and not line.startswith('#'))
    content = json.loads((ROOT / 'src/backend/evaluation/participant-content.json').read_text())
    manifest = {'version': version, 'revision': f'{version}+{digest[:12]}', 'sourceSha256': digest,
                'artefactSha256': pin['sha256'], 'files': files,
                **{k: content[k] for k in ('instrumentVersion', 'contentVersion', 'studyVersion')}}
    (ROOT / 'release.json').write_text(json.dumps(manifest, indent=2) + '\n')
    print(manifest['revision'])


if __name__ == '__main__':
    build(sys.argv[1])
