"""Development checkouts must not advertise a stale packaged release."""
import json
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from src.backend.release import metadata


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
