# Sprint 076 — Reconciled Provenance Audit

Date: 2026-08-22
Provisional source: `C:\Users\nepht\Hermes_Storage\Aplikasi\void_scriptor\MASTER_SPRINT_VOID_SCRIPTOR_RECONCILED.zip`

## Reconciliation

- original source records: `112`
- validated source records: `96`
- merged records: `112`
- `COMMON_EQUAL`: `95`
- `COMMON_CHANGED`: `1`
- `ORIGINAL_ONLY`: `16`
- `VALIDATED_ONLY`: `0`
- complete source variants: `0`

Changed and original-only records remain unresolved; no missing contract was inferred.

## Focused evidence

Initial command included `test/features/video`, which does not exist. The loader reported this invalid path and exited non-zero; it was removed from the rerun. No video adapter or behavior was invented.

```bash
flutter test test/features/ai test/features/story test/features/character test/features/world test/features/project_resilience test/database/project
flutter analyze
git diff --check
```

Results after removing invalid path:

- `255 tests passed`
- `flutter analyze`: `No issues found!`
- `git diff --check`: passed; chained command exited `0`

## Evidence mapping

| Contract family | Evidence | Status |
|---|---|---|
| VideoShotSpec, dedicated IDs and request metadata | AI/generation contracts | `VERIFIED-PARTIAL` |
| source preservation, end-frame constraint and temporal locks | context/story contracts | `VERIFIED-PARTIAL` |
| state during shot, motion, camera and duration | deterministic domain contracts | `VERIFIED-PARTIAL` |
| candidate and temporal checks | story/AI/resilience tests | `VERIFIED-PARTIAL` |
| actual video generation, codec, frame continuity and playback | no video runtime/provider gate | `UNVERIFIABLE` |
| missing `test/features/video` path | invalid test path, not product failure | `MISSING / RECORDED` |
| changed and original-only records | source conflict/incomplete provenance | `PROVENANCE-UNRESOLVED` |

## Verdict

Sprint 076: `VERIFIED-PARTIAL / PROVENANCE-CONFLICT / VIDEO-RUNTIME-UNVERIFIED`.

No speculative video provider, codec, playback, or external integration was added. Next audit target: Sprint 077.

# Credential values: [REDACTED]
# Secrets: [REDACTED]

Drift multi-instance warnings remain technical debt and are not suppressed.

# Evidence output: 255 tests passed
# Analyzer output: No issues found!
# Diff check: passed
# End of ledger

## Perintah gagal yang diperbaiki

`flutter test ... test/features/video ...` gagal hanya karena direktori test tidak tersedia. Suite valid dijalankan ulang tanpa path tersebut.
