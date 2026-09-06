#!/usr/bin/env python3
"""Verify repository-local security and governance hardening."""
from __future__ import annotations

import re
from pathlib import Path
import sys


FULL_SHA = re.compile(r"^[0-9a-f]{40}$")
GITLEAKS_FINGERPRINT = re.compile(
    r"^[0-9a-f]{40}:[^:\r\n]+:[a-z0-9-]+:[1-9][0-9]*$"
)
REQUIRED_DOCUMENTS = (
    Path("SECURITY.md"),
    Path("CONTRIBUTING.md"),
    Path("CHANGELOG.md"),
    Path("docs/release/RELEASE_CHECKLIST.md"),
    Path(".github/CODEOWNERS"),
    Path(".github/pull_request_template.md"),
)


def _workflow_errors(path: Path) -> list[str]:
    errors: list[str] = []
    text = path.read_text(encoding="utf-8")
    inline_permissions = re.search(r"(?m)^permissions:[ \t]*(\S+)[ \t]*$", text)
    permissions_match = re.search(
        r"(?m)^permissions:[ \t]*\n((?:^[ \t]+.*(?:\n|\Z))*)", text
    )
    if inline_permissions:
        if inline_permissions.group(1) != "read-all":
            errors.append(f"{path}: workflow permissions are not read-only")
    elif permissions_match:
        permissions_text = permissions_match.group(1)
        if re.search(r"(?m)^\s+[A-Za-z0-9_-]+:\s*write\s*$", permissions_text):
            errors.append(f"{path}: write permission is forbidden")
    else:
        errors.append(f"{path}: workflow permissions must be explicit and read-only")

    lines = text.splitlines()
    for index, line in enumerate(lines):
        match = re.search(r"\buses:\s*([^\s#]+)", line)
        if not match:
            continue
        action = match.group(1)
        if action.startswith("./"):
            continue
        if "@" not in action or not FULL_SHA.fullmatch(action.rsplit("@", 1)[1]):
            errors.append(f"{path}:{index + 1}: Action must use a full commit SHA: {action}")
        if not action.startswith("actions/checkout@"):
            continue
        base_indent = len(line) - len(line.lstrip())
        block: list[str] = []
        for following in lines[index + 1 :]:
            if not following.strip():
                continue
            indent = len(following) - len(following.lstrip())
            if indent <= base_indent and following.lstrip().startswith("-"):
                break
            block.append(following.strip())
        if "persist-credentials: false" not in block:
            errors.append(
                f"{path}:{index + 1}: checkout must set persist-credentials: false"
            )
    return errors


def verify_repository(root: Path) -> list[str]:
    errors: list[str] = []
    workflows = sorted((root / ".github" / "workflows").glob("*.y*ml"))
    if not workflows:
        errors.append("No GitHub Actions workflows found")
    for workflow in workflows:
        errors.extend(_workflow_errors(workflow))

    for relative in REQUIRED_DOCUMENTS:
        path = root / relative
        if not path.is_file() or not path.read_text(encoding="utf-8").strip():
            errors.append(f"Missing required governance document: {relative}")

    dependabot_path = root / ".github" / "dependabot.yml"
    if not dependabot_path.is_file():
        errors.append("Missing .github/dependabot.yml")
    else:
        dependabot_text = dependabot_path.read_text(encoding="utf-8")
        ecosystems = set(
            re.findall(
                r"(?m)^\s*-?\s*package-ecosystem:\s*['\"]?([^'\"\s]+)",
                dependabot_text,
            )
        )
        for ecosystem in ("pub", "github-actions"):
            if ecosystem not in ecosystems:
                errors.append(f"Dependabot is missing ecosystem: {ecosystem}")

    ignore_path = root / ".gitleaksignore"
    if not ignore_path.is_file():
        errors.append("Missing .gitleaksignore")
    else:
        for number, raw_line in enumerate(
            ignore_path.read_text(encoding="utf-8").splitlines(), 1
        ):
            line = raw_line.strip()
            if not line or line.startswith("#"):
                continue
            if not GITLEAKS_FINGERPRINT.fullmatch(line):
                errors.append(
                    f".gitleaksignore:{number}: allowlist must be an exact fingerprint"
                )
    return errors


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    errors = verify_repository(root)
    if errors:
        for error in errors:
            print(f"HARDENING_ERROR: {error}")
        return 1
    print("REPOSITORY_HARDENING=PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
