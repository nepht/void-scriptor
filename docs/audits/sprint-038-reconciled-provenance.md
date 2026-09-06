# Sprint 038 — Reconciled Provenance Audit

Date: 2026-08-22
Provisional source: `C:\Users\nepht\Hermes_Storage\Aplikasi\void_scriptor\MASTER_SPRINT_VOID_SCRIPTOR_RECONCILED.zip`

## Reconciliation

- original: `41`
- validated: `41`
- merged: `41`
- `COMMON_EQUAL`: `41`
- `COMMON_CHANGED`: `0`
- `ORIGINAL_ONLY`: `0`
- `VALIDATED_ONLY`: `0`
- complete source variants: `1`

## Focused evidence

```bash
flutter test test/features/character test/features/character_mode test/features/story test/features/world test/features/ai test/features/relations test/database/project test/features/project_resilience
```

Initial invocation included nonexistent `test/features/search` and failed only at test-loader level. Corrected invocation result: `277 tests passed`.

## Evidence mapping

| Contract family | Evidence | Status |
|---|---|---|
| character/entity/version/relations foundations | character, character-mode and relations tests | `VERIFIED-LOCAL` |
| story context, continuity and timeline | story context/persistence/timeline tests | `VERIFIED-LOCAL` |
| world simulation and universe-adjacent models | world domain/presentation tests | `VERIFIED-PARTIAL` |
| AI context/retrieval/provider boundaries | AI composer, budgeter, provider, generation and persistence tests | `VERIFIED-PARTIAL` |
| semantic/vector/embedding search | no vector index or embedding runtime evidence | `UNVERIFIABLE` |
| knowledge graph engine and visualization | relation foundations exist; dedicated graph engine not proven | `PARTIAL` |
| LLM universe assistant and knowledge prompt generation | provider contracts exist; external generation not exercised | `UNVERIFIABLE` |
| canon manager collaboration/approval | no dedicated canon collaboration runtime evidence | `UNVERIFIABLE` |
| alternate universes/what-if/full world simulation | bounded local models only; no production branch/runtime gate | `PARTIAL` |
| migration/resilience | project migration, recovery, command history and portable project tests | `VERIFIED-PARTIAL` |

## Boundary

Local entity, relation, continuity, bounded world-model and AI-context behavior are evidenced. Vector retrieval, external semantic generation, hosted collaboration, alternate-universe production branching and full simulation runtime remain unverified.

## Verdict

Sprint 038: `VERIFIED-PARTIAL / SEMANTIC-KNOWLEDGE-RUNTIME-UNVERIFIED`.

No production source was changed. Next audit target: Sprint 039.
# Evidence output: 277 tests passed
# Credential values: [REDACTED]
# Secrets: [REDACTED]
