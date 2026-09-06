from __future__ import annotations

import importlib.util
from pathlib import Path
import tempfile
import textwrap
import unittest


MODULE_PATH = (
    Path(__file__).resolve().parents[2] / "tools" / "verify_repository_hardening.py"
)


def _load_module():
    spec = importlib.util.spec_from_file_location("verify_repository_hardening", MODULE_PATH)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Unable to load {MODULE_PATH}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class VerifyRepositoryHardeningTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temp_dir = tempfile.TemporaryDirectory()
        self.root = Path(self.temp_dir.name)
        (self.root / ".github" / "workflows").mkdir(parents=True)
        (self.root / ".github" / "CODEOWNERS").write_text("* @owner\n")
        (self.root / ".github" / "pull_request_template.md").write_text("## Evidence\n")
        (self.root / "SECURITY.md").write_text("# Security\n")
        (self.root / "CONTRIBUTING.md").write_text("# Contributing\n")
        (self.root / "CHANGELOG.md").write_text("# Changelog\n")
        (self.root / "docs" / "release").mkdir(parents=True)
        (self.root / "docs" / "release" / "RELEASE_CHECKLIST.md").write_text(
            "# Checklist\n"
        )
        (self.root / ".github" / "dependabot.yml").write_text(
            textwrap.dedent(
                """
                version: 2
                updates:
                  - package-ecosystem: pub
                    directory: /
                    schedule: {interval: weekly}
                  - package-ecosystem: github-actions
                    directory: /
                    schedule: {interval: weekly}
                """
            ).lstrip()
        )
        (self.root / ".gitleaksignore").write_text(
            "0123456789abcdef0123456789abcdef01234567:test/a_test.dart:generic-api-key:12\n"
        )

    def tearDown(self) -> None:
        self.temp_dir.cleanup()

    def _write_workflow(self, body: str) -> None:
        (self.root / ".github" / "workflows" / "ci.yml").write_text(
            textwrap.dedent(body).lstrip()
        )

    def test_accepts_full_sha_read_only_checkout_without_persisted_credentials(self) -> None:
        module = _load_module()
        self._write_workflow(
            """
            name: CI
            on: [push]
            permissions:
              contents: read
            jobs:
              test:
                runs-on: ubuntu-latest
                steps:
                  - uses: actions/checkout@0123456789abcdef0123456789abcdef01234567
                    with:
                      persist-credentials: false
            """
        )

        self.assertEqual(module.verify_repository(self.root), [])

    def test_rejects_mutable_action_and_persisted_checkout_credentials(self) -> None:
        module = _load_module()
        self._write_workflow(
            """
            name: CI
            on: [push]
            permissions:
              contents: write
            jobs:
              test:
                runs-on: ubuntu-latest
                steps:
                  - uses: actions/checkout@v4
            """
        )

        errors = module.verify_repository(self.root)

        self.assertTrue(any("full commit SHA" in error for error in errors))
        self.assertTrue(any("persist-credentials" in error for error in errors))
        self.assertTrue(any("write permission" in error for error in errors))

    def test_rejects_broad_gitleaks_ignore_entries(self) -> None:
        module = _load_module()
        self._write_workflow(
            """
            name: CI
            on: [push]
            permissions:
              contents: read
            jobs:
              test:
                runs-on: ubuntu-latest
                steps:
                  - uses: actions/checkout@0123456789abcdef0123456789abcdef01234567
                    with:
                      persist-credentials: false
            """
        )
        (self.root / ".gitleaksignore").write_text("test/**\n")

        errors = module.verify_repository(self.root)

        self.assertTrue(any("exact fingerprint" in error for error in errors))


if __name__ == "__main__":
    unittest.main()
