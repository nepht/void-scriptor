#!/usr/bin/env python3
"""Generate deterministic release SBOM and third-party notices."""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
from typing import Any

LICENSE_NAMES = (
    "LICENSE",
    "LICENSE.md",
    "LICENSE.txt",
    "COPYING",
    "COPYING.txt",
)


def _hosted_packages(graph: dict[str, Any]) -> list[dict[str, Any]]:
    packages = [
        package
        for package in graph.get("packages", [])
        if package.get("source") == "hosted"
    ]
    return sorted(packages, key=lambda item: (item["name"], item["version"]))


def _license_text(pub_cache: Path, name: str, version: str) -> str:
    package_dir = pub_cache / "hosted" / "pub.dev" / f"{name}-{version}"
    for filename in LICENSE_NAMES:
        path = package_dir / filename
        if path.is_file():
            return path.read_text(encoding="utf-8", errors="replace").rstrip() + "\n"
    raise RuntimeError(f"Missing license for hosted package {name} {version}")


def generate_metadata(
    graph: dict[str, Any],
    pub_cache: Path,
    sbom_path: Path,
    notices_path: Path,
) -> None:
    packages = _hosted_packages(graph)
    components = [
        {
            "type": "library",
            "bom-ref": f"pkg:pub/{package['name']}@{package['version']}",
            "name": package["name"],
            "version": package["version"],
            "purl": f"pkg:pub/{package['name']}@{package['version']}",
        }
        for package in packages
    ]
    root_name = graph.get("root", "unknown")
    root = next(
        (package for package in graph.get("packages", []) if package.get("name") == root_name),
        {"name": root_name, "version": "unknown"},
    )
    sbom = {
        "bomFormat": "CycloneDX",
        "specVersion": "1.5",
        "version": 1,
        "metadata": {
            "component": {
                "type": "application",
                "name": root.get("name", root_name),
                "version": root.get("version", "unknown"),
            }
        },
        "components": components,
    }

    notices = ["THIRD-PARTY NOTICES\n", "===================\n\n"]
    for package in packages:
        title = f"{package['name']} {package['version']}"
        notices.extend(
            [
                f"{title}\n",
                f"{'-' * len(title)}\n",
                _license_text(pub_cache, package["name"], package["version"]),
            ]
        )

    sbom_path.parent.mkdir(parents=True, exist_ok=True)
    notices_path.parent.mkdir(parents=True, exist_ok=True)
    sbom_path.write_text(
        json.dumps(sbom, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    notices_path.write_text("".join(notices), encoding="utf-8")


def generate_artifact_manifest(artifacts_dir: Path, manifest_path: Path) -> None:
    """Write a deterministic manifest for files in a release artifact tree."""
    artifacts = []
    for path in sorted(item for item in artifacts_dir.rglob("*") if item.is_file()):
        relative = path.relative_to(artifacts_dir).as_posix()
        digest = hashlib.sha256(path.read_bytes()).hexdigest()
        artifacts.append(
            {"path": relative, "size": path.stat().st_size, "sha256": digest}
        )
    manifest_path.parent.mkdir(parents=True, exist_ok=True)
    manifest_path.write_text(
        json.dumps(
            {"format": "void-scriptor-release-manifest-v1", "artifacts": artifacts},
            indent=2,
            sort_keys=True,
        )
        + "\n",
        encoding="utf-8",
    )


def _dependency_graph(flutter: str, project_root: Path) -> dict[str, Any]:
    result = subprocess.run(
        [flutter, "pub", "deps", "--json"],
        cwd=project_root,
        check=True,
        capture_output=True,
        text=True,
    )
    return json.loads(result.stdout)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--flutter", default="flutter")
    parser.add_argument(
        "--pub-cache",
        type=Path,
        default=Path(os.environ.get("PUB_CACHE", Path.home() / ".pub-cache")),
    )
    parser.add_argument("--output-dir", type=Path, default=Path("build/release-metadata"))
    parser.add_argument(
        "--artifacts-dir",
        type=Path,
        help="Optional release artifact directory to checksum",
    )
    parser.add_argument(
        "--manifest-path",
        type=Path,
        help="Optional output path for the deterministic artifact manifest",
    )
    args = parser.parse_args(argv)

    if (args.artifacts_dir is None) != (args.manifest_path is None):
        parser.error("--artifacts-dir and --manifest-path must be provided together")

    project_root = Path(__file__).resolve().parents[1]
    graph = _dependency_graph(args.flutter, project_root)
    generate_metadata(
        graph,
        args.pub_cache,
        args.output_dir / "sbom.cdx.json",
        args.output_dir / "THIRD_PARTY_NOTICES.txt",
    )
    if args.artifacts_dir is not None and args.manifest_path is not None:
        generate_artifact_manifest(args.artifacts_dir, args.manifest_path)
    print(f"RELEASE_METADATA_READY: {args.output_dir}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
