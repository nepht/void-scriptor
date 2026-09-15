# Login UI refresh — 2026-09-11

Status: VERIFIED for focused widget/regression tests, analyzer and Windows debug build. Installed/mirror executable and native account-provider journey have not been verified or deployed in this task.

## Owned files

- lib/features/authentication/presentation/login_screen.dart
- test/features/authentication/login_screen_test.dart
- test/features/authentication/goldens/login_desktop.png
- docs/evidence/login-ui-refresh-2026-09-11.md

Existing unrelated worktree changes were preserved. No commit, push, Hermes job, authentication backend or brand asset was changed.

## Changes

Integrated background and responsive two-column desktop composition; single-column compact/large-text layout; brand-purple controls; bounded pointer-responsive logo with reduced-motion support; keyboard submission/focus; required credential validation. Removed simulated OAuth buttons and nonfunctional remember-me control, replacing OAuth with an explicit availability note. Guest/offline and existing login/register/recovery callbacks remain available.

## Evidence

Working directory: D:/VoidScriptor/void_scriptor_multiplatform

- RED: `flutter test test/features/authentication/login_screen_test.dart --reporter compact` failed against the previous UI: missing desktop composition and 116px horizontal overflow at 390px / 200% text.
- `dart format lib/features/authentication/presentation/login_screen.dart test/features/authentication/login_screen_test.dart` — formatted owned Dart files.
- `flutter test test/features/authentication/login_screen_test.dart --update-goldens --reporter expanded` — 2 passed after shared-preferences mock and asset/font preload; desktop PNG visually inspected.
- `flutter test test/core/auth test/features/authentication --reporter expanded` — 14 passed, including normal golden comparison and narrow 200% text.
- `flutter analyze --no-pub` — No issues found, 24.5s.
- `git -c safe.directory=D:/VoidScriptor/void_scriptor_multiplatform diff --check` — exit 0.
- `flutter build windows --debug --no-pub` — PASS, 62.4s; output build/windows/x64/runner/Debug/void_scriptor.exe.
- antislop-human contrast helper: muted text #B9B3C7 on #0C1019 = 9.36:1; input boundary #797386 on #151A26 = 3.82:1 (passes 3:1 non-text criterion; not a normal-text color).

Flutter/Dart commands use D:/DevTools/Flutter SDK/flutter/bin. Accessibility/UI guidance shaped contrast, focus, restrained motion and large-text behavior; missing antislop core file was disclosed. These are scoped checks, not a full accessibility certification.

Next action: native visual check of this rebuilt executable at the user's display scaling, then deploy through the normal release/mirror workflow. Actual Google/GitHub OAuth remains unavailable and is not represented as functional.
