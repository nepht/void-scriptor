from __future__ import annotations

import importlib.util
import json
from pathlib import Path
import tempfile
import unittest


MODULE_PATH = (
    Path(__file__).resolve().parents[2] / "tools" / "generate_release_candidate.py"
)


def _load_module():
    spec = importlib.util.spec_from_file_location("generate_release_candidate", MODULE_PATH)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Unable to load {MODULE_PATH}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class GenerateReleaseCandidateTest(unittest.TestCase):
    def test_loads_verified_signing_evidence_without_private_material(self):
        module = _load_module()
        with tempfile.TemporaryDirectory() as temp:
            signing_manifest = Path(temp) / "signing.json"
            signing_manifest.write_text(
                json.dumps(
                    {
                        "signing": {
                            "status": "SELF_SIGNED_LOCAL_VERIFIED",
                            "algorithm": "Authenticode-SHA256",
                            "verification_exit_code": 0,
                            "key_material": "NOT_PRESENT_IN_REPOSITORY",
                        }
                    }
                ),
                encoding="utf-8",
            )

            signing = module.load_signing_evidence(signing_manifest)

            self.assertEqual(signing["status"], "SELF_SIGNED_LOCAL_VERIFIED")
            self.assertEqual(signing["verification_exit_code"], 0)

    def test_manifest_captures_version_dependencies_schema_flags_and_provenance(self):
        module = _load_module()
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            artifact = root / "artifact"
            artifact.mkdir()
            (artifact / "void_scriptor.txt").write_text("rc payload\n", encoding="utf-8")
            output = root / "manifest.json"

            module.generate_release_candidate_manifest(
                artifact_dir=artifact,
                output_path=output,
                version="1.2.0-rc.1",
                project_format_major=1,
                project_format_schema=16,
                database_schema=62,
                feature_flags={"vs12_world_logic_shared": False},
                dependency_lock_sha256="lock-sha",
                build_command="flutter build windows --debug --no-pub",
                source_revision="abc123",
                signing={"status": "UNSIGNED_LOCAL_ONLY", "algorithm": "Ed25519"},
            )

            document = json.loads(output.read_text(encoding="utf-8"))
            self.assertEqual(document["version"], "1.2.0-rc.1")
            self.assertEqual(document["schema"]["database"], 62)
            self.assertEqual(document["flags"]["vs12_world_logic_shared"], False)
            self.assertEqual(document["dependencies"]["pubspec_lock_sha256"], "lock-sha")
            self.assertEqual(document["build_provenance"]["source_revision"], "abc123")
            self.assertEqual(document["signing"]["status"], "UNSIGNED_LOCAL_ONLY")
            self.assertEqual(document["artifacts"][0]["path"], "void_scriptor.txt")
            self.assertEqual(len(document["artifacts"][0]["sha256"]), 64)

    def test_manifest_is_deterministic_for_same_inputs(self):
        module = _load_module()
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            artifact = root / "artifact"
            artifact.mkdir()
            (artifact / "a.txt").write_text("same\n", encoding="utf-8")
            kwargs = dict(
                artifact_dir=artifact,
                version="1.2.0-rc.1",
                project_format_major=1,
                project_format_schema=16,
                database_schema=62,
                feature_flags={"vs12_world_logic_shared": False},
                dependency_lock_sha256="lock-sha",
                build_command="flutter build windows --debug --no-pub",
                source_revision="abc123",
                signing={"status": "UNSIGNED_LOCAL_ONLY", "algorithm": "Ed25519"},
            )
            first = root / "first.json"
            second = root / "second.json"
            module.generate_release_candidate_manifest(output_path=first, **kwargs)
            module.generate_release_candidate_manifest(output_path=second, **kwargs)
            self.assertEqual(first.read_bytes(), second.read_bytes())


if __name__ == "__main__":
    unittest.main()
