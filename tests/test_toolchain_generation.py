from pathlib import Path
from tempfile import TemporaryDirectory
import unittest
from unittest.mock import patch

from src.backend.toolchain import generate_curated
from src.backend.toolchain.curated import ToolchainError


class CuratedGenerationTests(unittest.TestCase):
    def test_toolchain_downloads_are_digest_and_checksum_pinned(self) -> None:
        dockerfile = (generate_curated.REPO_ROOT / "Dockerfile.toolchain").read_text(
            encoding="utf-8"
        )

        ubuntu_pin = (
            "ubuntu:24.04@sha256:"
            "1e0a86e57d247923571b75e0aaf48a1449cf8c543d51fb3e07a4a7d7bfa79316"
        )
        self.assertEqual(dockerfile.count(f"FROM {ubuntu_pin}"), 2)
        self.assertIn(
            "ARG LLVM_SHA256=df0e1ecf16caf3489a272a5eea4eec9b0d82878f6477fa309504f918a0006384",
            dockerfile,
        )
        self.assertIn('sha256sum --check --strict', dockerfile)

    def test_failed_generation_preserves_the_last_good_snapshot(self) -> None:
        with TemporaryDirectory() as temporary:
            live_root = Path(temporary) / "curated"
            live_root.mkdir()
            (live_root / "last-good.txt").write_text("last good", encoding="utf-8")

            def fail_after_partial_output(staging_root: Path) -> None:
                (staging_root / "partial.txt").write_text("partial", encoding="utf-8")
                raise ToolchainError("simulated generation failure")

            with patch.object(
                generate_curated,
                "_generate_snapshot",
                side_effect=fail_after_partial_output,
            ):
                with self.assertRaisesRegex(ToolchainError, "simulated"):
                    generate_curated.generate_all(artefacts_root=live_root)

            self.assertEqual(
                (live_root / "last-good.txt").read_text(encoding="utf-8"),
                "last good",
            )
            self.assertFalse((live_root / "partial.txt").exists())
            self.assertEqual(list(Path(temporary).iterdir()), [live_root])

    def test_successful_generation_replaces_the_snapshot_and_cleans_backup(self) -> None:
        with TemporaryDirectory() as temporary:
            live_root = Path(temporary) / "curated"
            live_root.mkdir()
            (live_root / "old.txt").write_text("old", encoding="utf-8")

            def complete_snapshot(staging_root: Path) -> None:
                (staging_root / "new.txt").write_text("new", encoding="utf-8")

            with patch.object(
                generate_curated,
                "_generate_snapshot",
                side_effect=complete_snapshot,
            ):
                generate_curated.generate_all(artefacts_root=live_root)

            self.assertFalse((live_root / "old.txt").exists())
            self.assertEqual(
                (live_root / "new.txt").read_text(encoding="utf-8"),
                "new",
            )
            self.assertEqual(list(Path(temporary).iterdir()), [live_root])

    def test_failed_snapshot_install_restores_the_previous_snapshot(self) -> None:
        with TemporaryDirectory() as temporary:
            live_root = Path(temporary) / "curated"
            staging_root = Path(temporary) / ".curated.staging-test"
            live_root.mkdir()
            staging_root.mkdir()
            (live_root / "last-good.txt").write_text("last good", encoding="utf-8")
            (staging_root / "new.txt").write_text("new", encoding="utf-8")
            original_replace = Path.replace

            def fail_staged_install(path: Path, target: Path) -> Path:
                if path == staging_root:
                    raise OSError("simulated install failure")
                return original_replace(path, target)

            with patch.object(Path, "replace", fail_staged_install):
                with self.assertRaisesRegex(ToolchainError, "Could not install"):
                    generate_curated._replace_snapshot(staging_root, live_root)

            self.assertEqual(
                (live_root / "last-good.txt").read_text(encoding="utf-8"),
                "last good",
            )
            self.assertFalse(generate_curated._backup_path(live_root).exists())

    def test_staging_directory_overlays_the_canonical_container_path(self) -> None:
        staging_root = Path("/tmp/staged-curated")

        command = generate_curated._docker_command(["clang", "--version"], staging_root)

        self.assertEqual(
            command,
            [
                "docker",
                "compose",
                "run",
                "--rm",
                "--no-TTY",
                "--volume",
                f"{staging_root}:/workspace/artefacts/curated",
                "toolchain",
                "clang",
                "--version",
            ],
        )


if __name__ == "__main__":
    unittest.main()
