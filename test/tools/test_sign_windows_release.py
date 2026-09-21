from __future__ import annotations

import os
import subprocess
from pathlib import Path
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "tools" / "sign_windows_release.ps1"


@unittest.skipUnless(os.name == "nt", "Windows signing contract")
class SignWindowsReleaseTest(unittest.TestCase):
    def test_invalid_thumbprint_fails_before_touching_artifacts(self):
        self.assertTrue(SCRIPT.is_file())
        with tempfile.TemporaryDirectory() as temp:
            artifact = Path(temp) / "void_scriptor.exe"
            artifact.write_bytes(b"unsigned fixture")
            result = subprocess.run(
                [
                    "powershell",
                    "-NoProfile",
                    "-NonInteractive",
                    "-File",
                    str(SCRIPT),
                    "-ArtifactDirectory",
                    temp,
                    "-CertificateThumbprint",
                    "not-a-thumbprint",
                    "-ExpectedSubject",
                    "CN=Void Scriptor Local Development",
                    "-SourceRevision",
                    "test-revision",
                    "-AllowSelfSignedLocal",
                ],
                capture_output=True,
                text=True,
                check=False,
            )
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("40 hexadecimal", result.stderr + result.stdout)
            self.assertEqual(artifact.read_bytes(), b"unsigned fixture")

    def test_script_is_fail_closed_and_emits_secret_free_evidence(self):
        source = SCRIPT.read_text(encoding="utf-8")
        self.assertIn("HasPrivateKey", source)
        self.assertIn("ExpectedSubject", source)
        self.assertIn("signtool", source.lower())
        self.assertIn("verify", source)
        self.assertIn("verification_exit_code", source)
        self.assertNotIn("PFX_PASSWORD", source)
        self.assertNotIn("PRIVATE KEY", source)


if __name__ == "__main__":
    unittest.main()
