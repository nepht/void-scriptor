# Sprint 21 — Project Bible + Canon Database

## Scope
Sprint 21 introduces a project-scoped canon and worldbuilding foundation:

- generic Bible entries with deterministic canon status and tags;
- structured canon rules and machine-readable conditions;
- factions, faction units, species, technology, power systems, abilities;
- terminology, timeline eras, historical events, and participants;
- persisted conflict findings, exceptions, resolution notes, and health summary;
- responsive Project Bible workspace at `/bible`;
- bounded relevant-canon context for AI scene context and prompt composition.

## Persistence
The live schema was audited before implementation. Sprint 21 migrations are:

```text
v17 → v18  BibleEntries
v18 → v19  CanonRules + CanonRuleConditions
v19 → v20  Factions
v20 → v21  Species + Technologies + PowerSystems + PowerAbilities
v21 → v22  TerminologyEntries + TimelineEras + HistoricalEvents + Participants
v22 → v23  FactionUnits
v23 → v24  CanonConflicts + CanonRuleExceptions
```

All Bible repositories enforce project-scoped reads. Domain models are kept separate from Drift row classes with explicit aliases where generated names collide.

## Canon validation
The deterministic validator currently supports:

- `forbiddenValue` with `contains` and `equals`;
- `uniqueness` using a bounded count snapshot;
- disabled rules;
- target exceptions;
- severity mapping to persisted conflict findings.

Conflict records can be resolved with an explicit note. `CanonHealthService` reports unresolved weighted findings using transparent weights: info=1, warning=2, error=3, critical=5. This is an operational indicator, not a claim of semantic completeness.

## AI/search context policy
The resolver never sends the whole Bible by default. It filters by:

- project ID;
- entity IDs;
- tags;
- relevant entry types (`overview` and `canonRule` as global context);
- canon status;
- deterministic limit and ordering.

`CanonPromptContextComposer` adds source labels and an explicit no-invention constraint. Scene AI context includes this bounded canon block while preserving existing character/environment/timeline context contracts.

## UI
`ProjectBibleWorkspaceScreen` provides:

- Universe Overview;
- Canon Rules;
- Worldbuilding;
- Timeline / Eras;
- Canon Conflicts;
- responsive desktop cards and narrow stacked layout;
- `/bible` route and desktop top-bar entry.

The current workspace is the first responsive integration slice. Data editors/inspectors and full conflict scan orchestration remain follow-up slices rather than being represented as complete here.

## Verification
Focused Bible, conflict, route, responsive UI, AI context, and prompt-context tests must remain green. Full project verification and CI exact-SHA evidence are required before calling the sprint release-ready.
