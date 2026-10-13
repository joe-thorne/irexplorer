"""Development checkouts must not advertise a stale packaged release, and the image builds with safe defaults."""
import json
import re
import shutil
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from scripts.build_release import IMAGE_FILES, source_fingerprint
from src.backend.release import ROOT, metadata


class ReleaseMetadataTests(unittest.TestCase):
    def test_checkout_ignores_stale_release_manifest(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root / '.git').mkdir()
            (root / 'release.json').write_text(json.dumps({'version': '0.1.0', 'revision': 'stale'}))
            with patch('src.backend.release.ROOT', root):
                self.assertEqual(metadata(), {'version': 'development', 'revision': 'development'})

    def test_packaged_manifest_is_used_without_git_checkout(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root / 'release.json').write_text(json.dumps({'version': '0.4.0', 'revision': 'current', 'files': {}}))
            with patch('src.backend.release.ROOT', root):
                self.assertEqual(metadata(), {'version': '0.4.0', 'revision': 'current'})


class ImageDefaultsTests(unittest.TestCase):
    def setUp(self):
        self.dockerfile = (ROOT / 'Dockerfile').read_text()

    def test_branch_builds_carry_a_0_6_0_development_version(self):
        # Until 0.6.0 is tagged, an image built from the user-programs branch is never mistaken for a release.
        # Moving the default to 0.6.0 itself is the deliberate act of tagging that release.
        default = re.search(r'^ARG APP_VERSION=(\S+)$', self.dockerfile, re.MULTILINE)
        self.assertRegex(default and default.group(1), r'^0\.6\.0-dev\.[1-9][0-9]*$')

    def test_image_leaves_user_programs_off(self):
        self.assertIn('IREXPLORER_USER_PROGRAMS=0', self.dockerfile)
        self.assertNotIn('IREXPLORER_COMPILER_URL', self.dockerfile)

    def test_the_user_programs_stack_defaults_to_the_dockerfile_version(self):
        # Both stacks build the same app image, so the user-programs stack must not fall back to another version.
        default = re.search(r'^ARG APP_VERSION=(\S+)$', self.dockerfile, re.MULTILINE).group(1)
        compose = (ROOT / 'compose.user-programs.yaml').read_text()
        self.assertIn(f'APP_VERSION: ${{IREXPLORER_VERSION:-{default}}}', compose)


class SourceFingerprintTests(unittest.TestCase):
    """The release identity says exactly what was built, user-programs stack included."""

    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        for name in (*IMAGE_FILES, 'src/backend/toolchain/compiler_service.py', 'examples/curated/score.c'):
            (self.root / name).parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(ROOT / name, self.root / name)
        (self.root / 'artefacts').mkdir()

    def test_the_user_programs_stack_and_compiler_service_change_the_fingerprint(self):
        for name in ('compose.user-programs.yaml', 'Dockerfile.compiler', 'src/backend/toolchain/compiler_service.py'):
            with self.subTest(name=name):
                before, files = source_fingerprint(self.root)
                self.assertIn(name, files)
                with (self.root / name).open('a') as file:
                    file.write('\n# changed\n')
                self.assertNotEqual(source_fingerprint(self.root)[0], before)

    def test_a_missing_image_input_stops_the_build(self):
        # The fingerprint is taken inside the image, so a file the Dockerfile forgot to copy must not pass silently.
        (self.root / 'compose.user-programs.yaml').unlink()
        with self.assertRaises(FileNotFoundError):
            source_fingerprint(self.root)

    def test_the_image_copies_every_file_the_fingerprint_names(self):
        runtime = (ROOT / 'Dockerfile').read_text().split(' AS test')[0]
        copied = {source for line in runtime.splitlines() if line.startswith('COPY ')
                  for source in line.split()[1:-1]}
        self.assertEqual(set(IMAGE_FILES) - copied, set())
