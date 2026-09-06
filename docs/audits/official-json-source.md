# Official Sprint Source — JSON Archive

Status: `CANONICAL CONTRACT SOURCE`

## Active location

```text
C:\Users\nepht\Documents\Codex\2026-08-22\referenced-chatgpt-conversation-this-is-an-2\outputs
```

Inventory verified on 2026-08-31:

- Validated recovery bundle: Sprint 001–100, 100 files, sequence PASS,
  7,251 recovered steps, 0 exact missing steps, 0 duplicates.
- Extension contracts: Sprint 101–151, 51 files, continuous range.
- Repository inventory: `docs/audits/sprint-1-151-review-matrix.json`.
- Latest corrective archive (`-an-2`) has precedence over older snapshots.

The former `docs/MASTER_SPRINT.md` snapshot was removed from the active tree
because it duplicated old conversation material and could override newer JSON
contracts during text search. Provenance remains in the external archive and
the reconciliation audits.

## Evidence boundary

JSON contracts define requirements, not implementation status. Repository
source, tests, builds, runtime evidence, and per-sprint ledgers determine
whether a step is VERIFIED, PARTIAL, BLOCKED, MISSING, or DEFERRED.

## Execution priority

Priority is governed by `docs/roadmap/ROADMAP_POLICY.json`. Corrective Sprint
145 is active and sequential Sprint 111 is suspended after 111.20. A contract
being present does not make it startable.

Before mutation run:

```text
dart run tool/roadmap_guard.dart
```

The guard checks the active policy, canonical contract, byte-identical Hermes
reference, per-sprint ledger, runtime pointer, and recoverable next step.
