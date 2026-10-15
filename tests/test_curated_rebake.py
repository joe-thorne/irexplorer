"""Guard the committed curated records with an offline re-bake.

Re-baking needs only the committed compiler artefacts and Python: no Docker
and no LLVM. A change to parsing, the model or the matcher that would alter a
curated record therefore fails here before it can reach the snapshot.
"""

import shutil
import unittest
from pathlib import Path
from tempfile import TemporaryDirectory

from src.backend.bake import bake_curated_snapshot
from src.backend.toolchain.curated import ARTEFACTS_ROOT
from src.backend.toolchain.integrity import verify_curated_snapshot


def _files_under(root: Path) -> dict[Path, bytes]:
    return {
        path.relative_to(root): path.read_bytes()
        for path in sorted(root.rglob("*"))
        if path.is_file()
    }


class CuratedRebakeTests(unittest.TestCase):
    maxDiff = None

    def test_rebaking_a_copy_reproduces_every_pinned_curated_record(self) -> None:
        with TemporaryDirectory() as temporary:
            copy_root = Path(temporary) / "curated"
            shutil.copytree(ARTEFACTS_ROOT, copy_root)
            model_dirs = sorted(copy_root.glob("*/model"))
            self.assertTrue(model_dirs, "the curated snapshot has no model records")
            for model_dir in model_dirs:
                shutil.rmtree(model_dir)

            bake_curated_snapshot(copy_root)

            committed = _files_under(ARTEFACTS_ROOT)
            rebaked = _files_under(copy_root)
            self.assertEqual(sorted(rebaked), sorted(committed))
            self.assertEqual(
                [path.as_posix() for path in committed if rebaked[path] != committed[path]],
                [],
                "re-baked records differ from the committed curated records",
            )
            verify_curated_snapshot(copy_root)


if __name__ == "__main__":
    unittest.main()
