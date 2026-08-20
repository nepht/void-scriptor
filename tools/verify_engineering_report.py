#!/usr/bin/env python3
"""Check the minimum evidence contract for an engineering report."""
from __future__ import annotations

import re
import sys

REQUIRED = {
    "status": re.compile(r"\b(VERIFIED|PARTIAL|BLOCKED|UNVERIFIABLE|MISSING|DEFERRED)\b"),
    "command": re.compile(r"(flutter|dart|git|wsl|hermes|uteke)\b", re.I),
    "evidence": re.compile(r"(test|analy[sz]e|build|evidence|output|result)", re.I),
    "next_action": re.compile(r"(next|blocker|berikutnya|tindakan)", re.I),
}


def check_report(text: str) -> list[str]:
    return [name for name, pattern in REQUIRED.items() if not pattern.search(text)]


def main() -> int:
    text = sys.stdin.read()
    missing = check_report(text)
    if missing:
        print("REPORT_INVALID: missing " + ", ".join(missing))
        return 1
    print("REPORT_VALID: evidence contract present")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
