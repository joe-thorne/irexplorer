import ast
import subprocess
import sys
import unittest
from pathlib import Path
from tempfile import TemporaryDirectory
from unittest.mock import patch

from src.backend import bake
from src.backend.toolchain import generate_curated
from src.backend.toolchain.curated import ToolchainError

TOOLCHAIN_PACKAGE = "src.backend.toolchain"
HIGHER_LAYERS = {"bake", "ingest", "model", "analysis", "api", "evaluation"}


def higher_layer_imports(source: str) -> list[str]:
    """Return ``line: module`` for each toolchain import of a higher layer.

    Parsing rather than text search sees imports deferred into function
    bodies and relative imports, and ignores comments and strings.
    """

    violations: list[tuple[int, str]] = []
    for node in ast.walk(ast.parse(source)):
        if isinstance(node, ast.Import):
            modules = [alias.name for alias in node.names]
        elif isinstance(node, ast.ImportFrom):
            base = node.module or ""
            if node.level:
                parent = TOOLCHAIN_PACKAGE.rsplit(".", node.level - 1)[0]
                base = f"{parent}.{base}" if base else parent
            modules = [base] if node.module else [f"{base}.{alias.name}" for alias in node.names]
        else:
            continue
        for module in modules:
            parts = module.split(".")
            if parts[:2] == ["src", "backend"] and len(parts) > 2 and parts[2] in HIGHER_LAYERS:
                violations.append((node.lineno, f"src.backend.{parts[2]}"))
    return [f"{line}: {module}" for line, module in sorted(violations)]


class CuratedGenerationTests(unittest.TestCase):
    def test_importing_generator_does_not_load_ingestion_or_analysis_layers(self) -> None:
        probe = (
            "import sys\n"
            "import src.backend.toolchain.generate_curated\n"
            "forbidden = sorted(name for name in sys.modules "
            "if name.startswith(('src.backend.ingest', 'src.backend.analysis')))\n"
            "print('\\n'.join(forbidden), file=sys.stderr)\n"
            "raise SystemExit(bool(forbidden))\n"
        )
        completed = subprocess.run(
            [sys.executable, "-c", probe],
            cwd=generate_curated.REPO_ROOT,
            capture_output=True,
            text=True,
            check=False,
        )

        self.assertEqual(completed.returncode, 0, completed.stderr)

    def test_boundary_scan_reads_imports_not_text(self) -> None:
        self.assertEqual(
            higher_layer_imports("# Layers above, such as src.backend.bake, read these files.\n"),
            [],
        )
        self.assertEqual(higher_layer_imports("from .. import bake\n"), ["1: src.backend.bake"])
        self.assertEqual(
            higher_layer_imports("def run():\n    from src.backend.ingest import curated\n"),
            ["2: src.backend.ingest"],
        )
        self.assertEqual(higher_layer_imports("from . import integrity\n"), [])

    def test_toolchain_source_never_imports_higher_layers(self) -> None:
        # The import probe above cannot see imports deferred into function bodies.
        toolchain_root = generate_curated.REPO_ROOT / "src" / "backend" / "toolchain"
        violations = [
            f"{path.name}:{violation}"
            for path in sorted(toolchain_root.glob("*.py"))
            for violation in higher_layer_imports(path.read_text(encoding="utf-8"))
        ]

        self.assertEqual(violations, [])

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
            ), self.assertRaisesRegex(ToolchainError, "simulated"):
                bake.generate_all(artefacts_root=live_root)

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
            ), patch.object(bake, "bake_curated_snapshot"):
                bake.generate_all(artefacts_root=live_root)

            self.assertFalse((live_root / "old.txt").exists())
            self.assertEqual(
                (live_root / "new.txt").read_text(encoding="utf-8"),
                "new",
            )
            self.assertEqual(list(Path(temporary).iterdir()), [live_root])

    def test_failed_snapshot_install_restores_the_previous_snapshot(self) -> None:
        with TemporaryDirectory() as temporary:
            live_root = Path(temporary) / "curated"
            live_root.mkdir()
            (live_root / "last-good.txt").write_text("last good", encoding="utf-8")
            original_replace = Path.replace

            def complete_snapshot(staging_root: Path) -> None:
                (staging_root / "new.txt").write_text("new", encoding="utf-8")

            def fail_staged_install(path: Path, target: Path) -> Path:
                if path.name.startswith(".curated.staging-"):
                    raise OSError("simulated install failure")
                return original_replace(path, target)

            with patch.object(
                generate_curated,
                "_generate_snapshot",
                side_effect=complete_snapshot,
            ), patch.object(bake, "bake_curated_snapshot"), patch.object(
                Path, "replace", fail_staged_install
            ), self.assertRaisesRegex(ToolchainError, "Could not install"):
                bake.generate_all(artefacts_root=live_root)

            self.assertEqual(
                (live_root / "last-good.txt").read_text(encoding="utf-8"),
                "last good",
            )
            self.assertFalse((live_root / "new.txt").exists())
            self.assertEqual(list(Path(temporary).iterdir()), [live_root])

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
