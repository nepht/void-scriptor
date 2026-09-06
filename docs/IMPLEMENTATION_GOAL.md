# Void Scriptor — Active Implementation Goal

Status: `CORRECTIVE CORE MVP ACTIVE`

## Product promise

Void Scriptor membantu novelis long-form merencanakan, menulis, menjaga
konsistensi, dan melindungi data proyek secara local-first di Windows.

## Current execution boundary

- Active stream: `corrective_core_mvp`.
- Active contract: external `sprint_145.json`.
- Active ledger: `docs/sprints/sprint-145-product-scope-reset-mvp-recovery.md`.
- First unresolved recovery candidate: `145.12`.
- Sequential feature expansion is suspended after verified `111.20` and may
  resume at `111.21` only after the Sprint 145 exit gate passes.
- Community, Reader Network, Publishing Network, Payment/Payout, Marketplace,
  provider expansion, XR, and Metaverse remain preserved but deferred.

## Source hierarchy

1. External JSON contract:
   `C:\Users\nepht\Documents\Codex\2026-08-22\referenced-chatgpt-conversation-this-is-an-2\outputs`.
2. Priority policy: `docs/roadmap/ROADMAP_POLICY.json`.
3. Per-sprint implementation ledger in `docs/sprints/`.
4. Disposable Hermes runtime cache: `.hermes/ROADMAP_STATE.json`.

Run `dart run tool/roadmap_guard.dart` before every autonomous mutation. A
guard failure blocks changes. Use `--repair` only while schedulers are paused.

## Core invariants

- Preserve project, novel, chapter, scene, character, lore, snapshot, backup,
  import/export, migration, and user-owned file compatibility.
- Core startup and editing must not require account, internet, AI provider,
  cloud, payment, marketplace, or community services.
- Exactly one roadmap mutation stream may be active.
- Corrective work overrides feature expansion until its exit gate passes.
- Never mark UI-only, domain-only, mock, placeholder, or historical evidence as
  a complete vertical slice.
- Never invent acceptance criteria or silently skip a blocked step.

## Verification contract

Every implemented slice requires focused RED/GREEN evidence, relevant
regression, analyzer, diff check, applicable Windows build/runtime evidence,
and a ledger update. Global claims require fresh global evidence.
