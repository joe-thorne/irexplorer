"""Fingerprint the actual image inputs, including uncommitted source changes."""
import hashlib
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
from src.backend.evaluation.content import participant_content  # noqa: E402
from src.backend.toolchain.integrity import verify_curated_snapshot  # noqa: E402 - needs ROOT on sys.path

# Files outside src/, examples/ and artefacts/ that the Dockerfile copies into the image to be fingerprinted there.
# Both stacks' Compose files and the compiler image are here; the compiler service's code is under src/.
IMAGE_FILES = ('Dockerfile', 'docker-compose.yml', 'compose.user-programs.yaml', 'Dockerfile.compiler',
               '.dockerignore', 'scripts/build_release.py', 'docs/curated-artefacts.sha256')


def source_fingerprint(root=ROOT):
    """The digest of every image input under ``root``, and each file's own digest.

    A missing image file raises, so a file the Dockerfile forgot to copy stops the build.
    """
    paths = [p for directory in ('src', 'examples', 'artefacts') for p in (root / directory).rglob('*')
             if p.is_file() and '__pycache__' not in p.parts]
    paths += [root / p for p in IMAGE_FILES]
    records = [(p.relative_to(root).as_posix(), hashlib.sha256(p.read_bytes()).hexdigest()) for p in sorted(paths)]
    digest = hashlib.sha256(''.join(f'{name}\0{digest}\n' for name, digest in records).encode()).hexdigest()
    return digest, dict(records)


def build(version):
    if not re.fullmatch(r'\d+\.\d+\.\d+(?:-[a-zA-Z0-9.-]+)?', version):
        raise ValueError('Use a semantic application version, for example 0.1.0')
    verify_curated_snapshot()
    digest, files = source_fingerprint()
    pin = dict(line.split('=', 1) for line in (ROOT / 'docs/curated-artefacts.sha256').read_text().splitlines()
               if line and not line.startswith('#'))
    content = participant_content()
    manifest = {'version': version, 'revision': f'{version}+{digest[:12]}', 'sourceSha256': digest,
                'artefactSha256': pin['sha256'], 'files': files,
                'packageSchemaVersion': content['packageSchemaVersion'],
                'packageIdentity': content['packageIdentity'],
                **{k: content[k] for k in ('instrumentVersion', 'contentVersion', 'studyVersion')}}
    (ROOT / 'release.json').write_text(json.dumps(manifest, indent=2) + '\n')
    print(manifest['revision'])


if __name__ == '__main__':
    build(sys.argv[1])
