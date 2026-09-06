# Sprint 020 — Reconciled Provenance Audit

Date: 2026-08-22
Provisional source: `C:\Users\nepht\Hermes_Storage\Aplikasi\void_scriptor\MASTER_SPRINT_VOID_SCRIPTOR_RECONCILED.zip`

## Reconciliation

- original: `47`
- validated: `40`
- merged: `47`
- `COMMON_EQUAL`: `17`
- `COMMON_CHANGED`: `23`
- `ORIGINAL_ONLY`: `7`
- `VALIDATED_ONLY`: `0`
- complete source variants: `0`

The archive retains seven original-only records and 23 changed records. These are provenance conflicts, not executable implementation instructions by themselves.

## Focused evidence

```bash
flutter test test/features/ai test/features/character test/features/character_mode test/features/assets test/features/inspector test/database/project
```

Result: `173 tests passed`.

## Evidence mapping

| Contract family | Evidence | Status |
|---|---|---|
| Reference ownership/priority/locks | character identity, references, modes and resolver tests | `VERIFIED-LOCAL` |
| Reference library/import/replace | asset/character/reference persistence and UI foundations | `VERIFIED-PARTIAL` |
| Image/overlay comparison | generation/reference review and comparison UI foundations | `VERIFIED-PARTIAL` |
| Consistency check/report | output review/reference service and context preservation | `VERIFIED-PARTIAL` |
| Regeneration/context/budget | AI generation, context budget and provider tests | `VERIFIED-PARTIAL` |
| Mode-specific reference sets | character-mode repository/picker/semantic rules | `VERIFIED-LOCAL` |
| Original-only/changed records | no unambiguous executable contract | `PROVENANCE-UNRESOLVED` |

## Boundary

The 173-test suite proves local character/reference/AI context foundations, persistence, review, mode integration, responsive UI, asset search and database gates. It does not prove visual fingerprint comparison, automated drift scoring, external image generation, production image processing or hosted synchronization.

## Known debt

Drift multiple-`ProjectDatabase` warnings remain visible in character repository tests; they do not fail the suite and are not suppressed.

## Verdict

Sprint 020: `VERIFIED-PARTIAL / HIGH-PROVENANCE-CONFLICT`.

No production source was changed because unresolved variants did not define a safe local fix. Next audit target: Sprint 021.
# Evidence output: 173 tests passed
