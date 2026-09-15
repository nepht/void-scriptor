# Master sprint entry point

This file is a NON_BINDING navigation index, not a replacement sprint contract.
It does not introduce requirements, acceptance criteria, or completion evidence.
Do not interpret its existence as completion of any sprint.

## Authoritative sources

- Priority and active stream: `docs/roadmap/ROADMAP_POLICY.json`.
- Document authority: `docs/roadmap/DOCUMENT_REGISTRY.json`.
- Governance explanation: `docs/roadmap/README.md`.
- Canonical sprint JSON: resolve the archive/reference roots from the policy;
  use the exact active stream contract and verify it with the roadmap guard.
- Implementation evidence: the active stream's ledger in `docs/sprints/`.
- Runtime cache only: `.hermes/ROADMAP_STATE.json`. It is not proof of completion.

## Resumption

Run `dart run tool/roadmap_guard.dart` from the repository before selecting work.
If it fails, diagnose the reported disagreement; do not invent missing content
or advance the pointer. Do not use `--repair` while another executor is active.

At inspection on 2026-09-08 the guard reported PASS, canonical sprint 145,
recommended step 145.27, last resolved step 145.26, canonical SHA-256
`86af6a53a27fda4e7b5abc9b2a868550e4c0926977617ae3498381a76c4d5fa9`.
This is a dated observation, not a hardcoded future execution pointer.

The active corrective Core MVP stream takes precedence over suspended expansion
111.21. Do not restart Sprint 1 or resume expansion simply because a task says
"implement every sprint". Read the canonical requirement, then the ledger's
latest evidence and outstanding subcriteria before changing code.

For 145.27 the canonical objective is Core Worldbuilding Reduction: prioritize
Characters, Locations, Factions, Timeline, Relationship Map, and Lore Notes;
keep other feature ambitions behind Advanced/backlog until user evidence.
The JSON objective is available, but it must not be mistaken for a complete
executable acceptance specification for every possible implementation.

Choose only an in-scope, evidence-backed remaining slice. Preserve uncommitted
changes and coordinate ownership before touching a region used by Hermes.
Use RED/GREEN tests for code changes and follow `AGENTS.md` verification gates.
Hardware/native criteria without suitable equipment remain explicitly
UNVERIFIABLE; simulations cannot be relabeled as physical-device evidence.
If a slice lacks a necessary product decision, request that specific decision
rather than declaring every contract missing or fabricating acceptance tests.

Read-only checks or independent, already specified work can continue while a
different criterion is blocked. A blocker never authorizes duplicate execution,
automatic publishing, changing immutable policy, or false completion.
