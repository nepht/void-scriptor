# Character reference layout — 2026-09-19

Status: PARTIAL for full screenshot parity; VERIFIED for automated layout tests,
analyzer and Windows debug build. Native visual comparison was not performed.

## Implemented

- Character → Appearance uses a 2:1 content/portrait composition at content widths
  >=820 px; narrow views and large text use a single column.
- Compact identity summary, 8 px gutters, four turnaround slots on wider cards.
- Portrait uses contain rather than cropping, with image-decode error guidance.
- Existing portrait/reference import paths retained. No copied fictional content.
- Removed hard-coded palette/accessory examples that could be mistaken for data.
- Inspector reads actual character properties; default width 280 px.
  Persisted user panel sizes are intentionally preserved.
- Existing section ownership and editing controls retained; no duplicate tabs added.

## Scope

Repository: `D:/VoidScriptor/void_scriptor_multiplatform`.
Owned files (relative to that repository):

- lib/features/character/presentation/character_workspace_screen.dart
- lib/features/character/presentation/widgets/character_design_sheet_layout.dart
- lib/features/character/presentation/widgets/character_identity_card.dart
- lib/features/character/presentation/widgets/character_portrait_card.dart
- lib/features/character/presentation/widgets/turnaround_card.dart
- lib/features/character/presentation/widgets/accessories_card.dart
- lib/features/character/presentation/widgets/color_palette_card.dart
- lib/features/inspector/presentation/inspector_panel.dart
- lib/features/inspector/presentation/inspectors/character_inspector.dart
- lib/features/workspace_layout/domain/layout_model.dart
- test/features/character/character_design_sheet_layout_test.dart
- test/features/workspace/character_section_ownership_test.dart
- test/features/workspace_layout/domain/layout_models_test.dart
- docs/evidence/character-sheet-layout-20260919.md

Kanban inspected: all listed cards done. Only one git worktree. Existing
sprint-112 evidence metadata preserved. No commit, push, cron change, release
deployment or sprint completion claim made.

## Commands and actual results

Run from repository root in PowerShell:

```powershell
& 'D:\DevTools\Flutter SDK\flutter\bin\flutter.bat' test --no-pub test/features/character/character_design_sheet_layout_test.dart
# RED: absent layout class, exit 1 before implementation.

& 'D:\DevTools\Flutter SDK\flutter\bin\flutter.bat' test --no-pub test/features/character test/features/workspace/character_section_ownership_test.dart -j 1
# PASS 112/112, exit 0.

& 'D:\DevTools\Flutter SDK\flutter\bin\flutter.bat' test --no-pub test/features/workspace/character_section_ownership_test.dart test/features/inspector -j 1
# PASS 45/45, exit 0. Drift emitted duplicate-instance warnings in existing tests.

& 'D:\DevTools\Flutter SDK\flutter\bin\flutter.bat' test --no-pub test/features/workspace_layout/domain/layout_models_test.dart
# RED: default expected 280, actual 310 before default change.

& 'D:\DevTools\Flutter SDK\flutter\bin\flutter.bat' test --no-pub test/features/workspace_layout test/features/character/character_design_sheet_layout_test.dart -j 1
# Final PASS 50/50, exit 0. Earlier equality fixture still used 310; updated to 280.

& 'D:\DevTools\Flutter SDK\flutter\bin\flutter.bat' analyze --no-pub
# Final: No issues found, exit 0 (21.9s). Earlier const hints corrected.

& 'D:\DevTools\Flutter SDK\flutter\bin\flutter.bat' build windows --debug --no-pub
# Final PASS, 36.6s. build/windows/x64/runner/Debug/void_scriptor.exe

git diff --check
# PASS exit 0. Git warns CRLF will normalize to LF for identity card.
```

Test groups overlap; counts must not be added as unique tests.

## Remaining work / next action

Open the new debug build, choose a character and Appearance, compare at actual
Windows display scaling with real imported art. Turnaround/silhouette remain
unbound placeholders, palette editing and screenshot-specific close-up tools
are not implemented by this layout slice. Do not mark full reference parity
or the parent sprint complete. A separate data-backed visual-slot slice is
needed to finish these features.

UI skill influenced responsive layout, preserved brand palette and removal of
fabricated data. Its companion antislop.md was not found in installed skill
roots; used the available UI guidance and the supplied reference.
