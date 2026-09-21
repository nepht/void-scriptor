#!/usr/bin/env python3
"""Generate a deterministic, secret-free RC reproducibility manifest."""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
from typing import Any


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _artifacts(artifact_dir: Path) -> list[dict[str, Any]]:
    return [
        {
            "path": path.relative_to(artifact_dir).as_posix(),
            "size": path.stat().st_size,
            "sha256": _sha256(path),
        }
        for path in sorted(item for item in artifact_dir.rglob("*") if item.is_file())
    ]


def load_signing_evidence(path: Path) -> dict[str, Any]:
    document = json.loads(path.read_text(encoding="utf-8"))
    signing = document.get("signing")
    if not isinstance(signing, dict):
        raise ValueError("Signing evidence must contain a signing object.")
    forbidden = {"password", "private_key", "pfx", "pfx_base64"}
    present_forbidden = forbidden.intersection(key.lower() for key in signing)
    if present_forbidden:
        raise ValueError("Signing evidence contains forbidden secret fields.")
    if signing.get("status") not in {
        "SELF_SIGNED_LOCAL_VERIFIED",
        "SIGNED_AND_VERIFIED",
    }:
        raise ValueError("Signing evidence is not verified.")
    if signing.get("verification_exit_code") != 0:
        raise ValueError("Signing evidence verification did not succeed.")
    return dict(signing)


def generate_release_candidate_manifest(
    *,
    artifact_dir: Path,
    output_path: Path,
    version: str,
    project_format_major: int,
    project_format_schema: int,
    database_schema: int,
    feature_flags: dict[str, bool],
    dependency_lock_sha256: str,
    build_command: str,
    source_revision: str,
    signing: dict[str, Any],
) -> None:
    document = {
        "format": "void-scriptor-rc-reproducibility-v1",
        "version": version,
        "artifacts": _artifacts(artifact_dir),
        "dependencies": {"pubspec_lock_sha256": dependency_lock_sha256},
        "schema": {
            "project_format_major": project_format_major,
            "project_format_schema": project_format_schema,
            "database": database_schema,
        },
        "flags": dict(sorted(feature_flags.items())),
        "build_provenance": {
            "source_revision": source_revision,
            "build_command": build_command,
        },
        "signing": signing,
    }
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(document, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("artifact_dir", type=Path)
    parser.add_argument("output_path", type=Path)
    parser.add_argument("--version", default="1.2.0-rc.1")
    parser.add_argument("--source-revision", default="unknown")
    parser.add_argument(
        "--build-command",
        default="flutter build windows --debug --no-pub",
    )
    parser.add_argument("--signing-manifest", type=Path)
    args = parser.parse_args()
    signing = (
        load_signing_evidence(args.signing_manifest)
        if args.signing_manifest is not None
        else {
            "status": "UNSIGNED_LOCAL_ONLY",
            "algorithm": "Authenticode-SHA256",
            "certificate_source": "NOT_CONFIGURED",
        }
    )
    generate_release_candidate_manifest(
        artifact_dir=args.artifact_dir,
        output_path=args.output_path,
        version=args.version,
        project_format_major=1,
        project_format_schema=16,
        database_schema=62,
        feature_flags={"vs12_world_logic_shared": False},
        dependency_lock_sha256=_sha256(Path("pubspec.lock")),
        build_command=args.build_command,
        source_revision=args.source_revision,
        signing=signing,
    )
    print(f"RC_MANIFEST_READY: {args.output_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
