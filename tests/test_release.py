"""Development checkouts must not advertise a stale packaged release, and the image builds with safe defaults."""
import json
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

    def test_image_leaves_user_programs_off(self):
        self.assertIn('IREXPLORER_USER_PROGRAMS=0', self.dockerfile)
        self.assertNotIn('IREXPLORER_COMPILER_URL', self.dockerfile)
