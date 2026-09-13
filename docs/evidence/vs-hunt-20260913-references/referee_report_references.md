# Referee Adjudication Report: References Region Bug Hunt

## Adjudication Summary

- **Total reported by Hunter:** 3
- **Dismissed as false positives:** 0
- **Confirmed as real bugs:** 3
- **Severity Breakdown:** Critical: 0 | Medium: 2 | Low: 1

---

## Detailed Bug Evaluations

### BUG-1
- **Hunter's claim:** The `replaceFile` method attempts to copy the current reference file to a version snapshot without verifying if the file exists on disk, causing unhandled `FileSystemException` crashes when replacing references whose underlying files are missing.
- **Skeptic's response:** ACCEPT (100% confidence).
- **Your analysis:** Independent code inspection of `lib/features/references/application/reference_repository.dart` (lines 373–404) confirms that while `source` file existence is verified, `target` file existence (`target.exists()`) is not checked prior to `await target.copy(snapshot.path)`. If the target reference file is missing on disk (due to external deletion or cleanup), a `FileSystemException` is thrown unhandled. Furthermore, an additional transactional/partial-failure issue exists: `dao.saveVersion(...)` executes *before* `source.copy(target.path)`, meaning a database version record is created and committed even if copying the replacement file subsequently fails.
- **VERDICT:** REAL BUG
- **Confidence:** High
- **True severity:** Medium
- **Suggested fix:** Check `if (await target.exists()) { await target.copy(snapshot.path); }` (or handle missing target gracefully) and reorder operations or wrap in a transaction so version history is only recorded upon successful file replacement.

---

### BUG-2
- **Hunter's claim:** Identity locks are rendered with `onChanged: null` inside `SwitchListTile`, permanently disabling the switch interaction and preventing users from toggling lock states in the management screen.
- **Skeptic's response:** ACCEPT (100% confidence).
- **Your analysis:** Independent inspection of `lib/features/references/presentation/reference_management_screen.dart` (lines 65–80) reveals that identity locks are mapped to `SwitchListTile` with `onChanged: null`. No callback exists on `ReferenceManagementScreen` or model binding to handle toggling lock states. While the screen currently has limited production routing, the widget implementation itself is non-interactive and permanently broken for users attempting to toggle lock states.
- **VERDICT:** REAL BUG
- **Confidence:** High
- **True severity:** Medium
- **Suggested fix:** Add an `onToggleLock` callback parameter to `ReferenceManagementScreen` and wire it up to the `onChanged` property of `SwitchListTile`.

---

### BUG-3
- **Hunter's claim:** The reference import dialog submission handler silently ignores empty required path or name fields without providing user feedback or error indication.
- **Skeptic's response:** ACCEPT (100% confidence).
- **Your analysis:** Independent inspection of `lib/features/references/presentation/reference_import_dialog.dart` (lines 91–112) confirms that the "Import" `FilledButton` has its `onPressed` permanently enabled (`onPressed: () => _submit(context)`). Inside `_submit`, if path or name is empty, it executes `if (path.text.trim().isEmpty || name.text.trim().isEmpty) return;` and silently returns without dismissing the dialog or presenting any validation feedback to the user.
- **VERDICT:** REAL BUG
- **Confidence:** High
- **True severity:** Low
- **Suggested fix:** Either disable the import button when required fields are empty (e.g. by wrapping dialog state or validation) or show a `SnackBar`/error message on submission attempt.

---

## VERIFIED BUG REPORT

Stats:
- Total reported by Hunter: 3
- Dismissed as false positives: 0
- Confirmed as real bugs: 3
- Critical: 0 | Medium: 2 | Low: 1

Confirmed bugs (ordered by severity):

| # | Severity | File | Line(s) | Description | Suggested Fix |
|---|----------|------|---------|-------------|---------------|
| BUG-1 | Medium | lib/features/references/application/reference_repository.dart | 397 | `replaceFile` copies target to snapshot without checking if target file exists on disk, causing unhandled `FileSystemException`. | Check `target.exists()` before copying; reorder `saveVersion` after successful copy. |
| BUG-2 | Medium | lib/features/references/presentation/reference_management_screen.dart | 73 | Identity lock `SwitchListTile` has `onChanged: null`, permanently disabling interaction. | Add `onToggleLock` callback and wire to `onChanged`. |
| BUG-3 | Low | lib/features/references/presentation/reference_import_dialog.dart | 99 | Import dialog submission silently ignores empty required fields without user feedback. | Disable import button when empty or add validation error feedback. |

Low-confidence items (flagged for manual review):
None. All 3 items evaluated with High confidence.
