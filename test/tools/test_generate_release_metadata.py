from __future__ import annotations

import importlib.util
import json
from pathlib import Path
import tempfile
import unittest


MODULE_PATH = (
    Path(__file__).resolve().parents[2] / "tools" / "generate_release_metadata.py"
)


def _load_module():
    spec = importlib.util.spec_from_file_location("generate_release_metadata", MODULE_PATH)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Unable to load {MODULE_PATH}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class GenerateReleaseMetadataTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temp_dir = tempfile.TemporaryDirectory()
        self.root = Path(self.temp_dir.name)
        self.cache = self.root / "pub-cache"
        package_dir = self.cache / "hosted" / "pub.dev" / "alpha-1.2.3"
        package_dir.mkdir(parents=True)
        (package_dir / "LICENSE").write_text("Alpha license\n", encoding="utf-8")
        self.graph = {
            "root": "void_scriptor",
            "packages": [
                {
                    "name": "void_scriptor",
                    "version": "0.1.0+1",
                    "kind": "root",
                    "source": "root",
                    "dependencies": ["alpha", "flutter"],
                },
                {
                    "name": "alpha",
                    "version": "1.2.3",
                    "kind": "direct",
                    "source": "hosted",
                    "dependencies": [],
                },
                {
                    "name": "flutter",
                    "version": "0.0.0",
                    "kind": "direct",
                    "source": "sdk",
                    "dependencies": [],
                },
            ],
        }

    def tearDown(self) -> None:
        self.temp_dir.cleanup()

    def test_generates_deterministic_cyclonedx_and_notices(self) -> None:
        module = _load_module()
        sbom = self.root / "sbom.cdx.json"
        notices = self.root / "THIRD_PARTY_NOTICES.txt"

        module.generate_metadata(self.graph, self.cache, sbom, notices)

        document = json.loads(sbom.read_text(encoding="utf-8"))
        self.assertEqual(document["bomFormat"], "CycloneDX")
        self.assertEqual(document["specVersion"], "1.5")
        self.assertEqual(
            [(item["name"], item["version"]) for item in document["components"]],
            [("alpha", "1.2.3")],
        )
        self.assertEqual(
            document["components"][0]["purl"], "pkg:pub/alpha@1.2.3"
        )
        self.assertNotIn("timestamp", document["metadata"])
        self.assertEqual(
            notices.read_text(encoding="utf-8"),
            "THIRD-PARTY NOTICES\n"
            "===================\n\n"
            "alpha 1.2.3\n"
            "-----------\n"
            "Alpha license\n",
        )

    def test_generates_deterministic_artifact_checksum_manifest(self) -> None:
        module = _load_module()
        artifacts = self.root / "artifacts"
        artifacts.mkdir()
        (artifacts / "b.txt").write_text("bravo\n", encoding="utf-8")
        (artifacts / "a.txt").write_text("alpha\n", encoding="utf-8")
        manifest = self.root / "manifest.json"

        module.generate_artifact_manifest(artifacts, manifest)

        document = json.loads(manifest.read_text(encoding="utf-8"))
        self.assertEqual(document["format"], "void-scriptor-release-manifest-v1")
        self.assertEqual(
            [item["path"] for item in document["artifacts"]],
            ["a.txt", "b.txt"],
        )
        self.assertEqual(document["artifacts"][0]["size"], 6)
        self.assertEqual(
            document["artifacts"][0]["sha256"],
            "b6a98d9ce9a2d9149288fa3df42d377c3e42737afdcdaf714e33c0a100b51060",
        )

    def test_fails_closed_when_hosted_license_is_missing(self) -> None:
        module = _load_module()
        (self.cache / "hosted" / "pub.dev" / "alpha-1.2.3" / "LICENSE").unlink()

        with self.assertRaisesRegex(RuntimeError, "alpha 1.2.3"):
            module.generate_metadata(
                self.graph,
                self.cache,
                self.root / "sbom.cdx.json",
                self.root / "THIRD_PARTY_NOTICES.txt",
            )


if __name__ == "__main__":
    unittest.main()
