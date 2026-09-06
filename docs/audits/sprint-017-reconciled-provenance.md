# Sprint 017 — Reconciled Provenance Audit

Date: 2026-08-22
Provisional source: `C:\Users\nepht\Hermes_Storage\Aplikasi\void_scriptor\MASTER_SPRINT_VOID_SCRIPTOR_RECONCILED.zip`

## Reconciliation

- original steps: `38`
- validated steps: `40`
- merged records: `40`
- `COMMON_EQUAL`: `16`
- `COMMON_CHANGED`: `22`
- `ORIGINAL_ONLY`: `0`
- `VALIDATED_ONLY`: `2`
- complete source variants: `0`

This sprint contains substantial unresolved source conflict. Changed and validated-only records remain explicitly unresolved.

## Focused evidence

The first invocation included nonexistent `test/core/ai`, producing a loader error. The valid test paths ran and produced 177 passing tests before the loader error was reported.

Command family:

```bash
flutter test test/features/ai test/core/agent test/features/story test/features/character test/features/inspector test/features/timeline
```

Observed valid evidence: `177 tests passed`; invocation exit was non-zero only because `test/core/ai` does not exist.

## Evidence mapping

| Contract family | Live evidence | Status |
|---|---|---|
| AI context/composer/compiler | target-specific sections, options, ordering and metadata | `VERIFIED-LOCAL` |
| Prompt editing/history | editable prompt, dirty state, diff/compare, restart persistence | `VERIFIED-LOCAL` |
| Provider registry/routing | capability registry, routing, fallback, timeout, rate limiting, cost and diagnostics | `VERIFIED-LOCAL` |
| Generation runtime | queue, retry/cancel, persistence, recovery and output review | `VERIFIED-LOCAL` |
| References/consistency | reference resolver and generation output review | `VERIFIED-PARTIAL` |
| AI workspace/UI | composer, context, review, usage, gallery and responsive controls | `VERIFIED-PARTIAL` |
| Agent/tool boundary | agent runtime, tool registry and explicit approval safety | `VERIFIED-PARTIAL` |

## Provenance boundary

Steps `17.1–17.8`, `17.10–17.13`, `17.16`, `17.19`, `17.21–17.22`, `17.24–17.25`, `17.27–17.28`, and `17.37–17.38` are `COMMON_CHANGED`; steps `17.39–17.40` are `VALIDATED_ONLY`. Their source variants remain unresolved and were not reconstructed from labels.

## Local warning

Known Drift multiple-`ProjectDatabase` warnings appeared in character repository tests. They do not fail the valid tests and remain technical debt.

## Boundary

Local tests prove a broad AI context/prompt/provider/generation foundation. They do not prove external provider connectivity, production credentials, media-provider availability, full agent orchestration, or production deployment.

## Verdict

Sprint 017: `VERIFIED-PARTIAL / HIGH-PROVENANCE-CONFLICT`.

No production source was changed: the observed local contracts are already implemented and unresolved source variants do not define a safe additional slice.

Next audit target: Sprint 018.
# Evidence output: 177 valid tests passed; initial invocation exit non-zero due only to nonexistent test/core/ai path
