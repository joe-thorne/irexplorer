"""Development checkouts must not advertise a stale packaged release, and the image builds with safe defaults."""
import json
import re
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

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

