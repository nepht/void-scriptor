# Contributing to Void Scriptor

## Canonical development environment

The canonical source tree is the WSL checkout. The verified toolchain is:

- Flutter `3.44.9` stable, revision `6b182d2c75`;
- Dart `3.12.2`;
- Java `17`;
- Linux build dependencies: CMake, Ninja, GTK 3, and libsecret development packages.

Windows native builds require a Windows-hosted Flutter SDK and Visual Studio Build Tools. Do not treat a Linux build as Windows evidence.

## Change discipline

1. Inspect `git status --short` before editing.
2. Preserve unrelated and concurrent changes.
3. Use RED → GREEN → REFACTOR for behavior changes.
4. Do not weaken tests to hide regressions.
5. Never commit credentials, generated signing material, or connection strings.
6. Keep commits scoped; do not use `git add -A` in a dirty shared worktree.

## Local verification

Run from the canonical WSL checkout:

```bash
/home/nepht/toolchain/flutter/bin/dart format --output=none --set-exit-if-changed lib test
/home/nepht/toolchain/flutter/bin/flutter analyze
/home/nepht/toolchain/flutter/bin/flutter test
python3 test/tools/test_generate_release_metadata.py -v
python3 tools/generate_release_metadata.py \
  --flutter /home/nepht/toolchain/flutter/bin/flutter
/home/nepht/toolchain/flutter/bin/flutter build linux --debug
/home/nepht/toolchain/flutter/bin/flutter build web --release
/home/nepht/toolchain/flutter/bin/flutter build apk --debug
git diff --check
```

Run focused tests first while developing. The broader gates above are required before integration.

## Pull requests

Describe:

- the contract or bug being addressed;
- RED and GREEN evidence for behavior changes;
- exact verification commands and results;
- files intentionally left untouched;
- known blockers or unverified platforms.

A written file, model, abstraction, or placeholder is not completion evidence. Report hosted CI as green only when a completed run succeeds on the exact submitted SHA.