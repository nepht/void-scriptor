# Sprint 145.29 — Lore Linking and Search

Tanggal audit: 2026-08-27  
Sumber kanonik: `sprint_145.json` langkah 145.29.  
Metode: inspeksi source/test live, TDD regression untuk project scope, focused test, dan scoped analyzer.

## Required contract

Mendukung fast discoverable link/reference ke characters, locations, factions, dan lore dengan broken-link handling, rename safety, scope, dan keyboard flow.

## Live evidence matrix

| Acceptance area | Evidence | Status |
|---|---|---|
| Fast link discovery | `LoreLinkSuggester` deterministic exact/prefix/substring ranking, dedupe, limit; Story Workspace autocomplete | VERIFIED |
| Link syntax | `InlineLoreLinkParser`/renderer preserve plain text, escaped openings, malformed links, whitespace, and round-trip content | VERIFIED |
| Keyboard flow | Arrow navigation, Enter accept, Escape close tested in Story Workspace | VERIFIED |
| Broken links | `LoreLinkClassifier` and `LoreBacklinkService.scanIntegrity` classify broken targets; report is deterministic | VERIFIED |
| Ambiguous links | Normalized duplicate catalog names become `ambiguous` with all candidates | VERIFIED |
| Rename safety | `ProjectLoreLinkEditor` changes only real `[[target]]` segments; plain text and escaped literals remain intact | VERIFIED |
| Project scope | Catalog and backlink collection filter by project; retarget now filters beats through project-owned stories/scenes | VERIFIED after regression fix |
| Lore creation | `CreateLoreEntityService` creates scoped Bible lore entries, trims names, rejects blank/duplicate names | VERIFIED |
| Characters/locations/factions catalog | `CreateLoreEntityService.loadCatalog` unifies project-scoped Characters (displayName), Environments/Locations (name), Factions (name) with Species, Technologies, PowerSystems, BibleEntries (`test/features/bible/lore_catalog_core_entities_test.dart` 3 PASS: unified kinds/ids/details, project scoping, duplicate lore creation blocked by character name) | VERIFIED (2026-09-02 cron, commit 054e274) |
| Global search UI | Domain/search seams exist, but complete cross-workspace search UI and navigation journey is not proven in this step | PARTIAL |
| Native Windows interaction | Driver previously returned `snapshot_id_required` | UNVERIFIABLE |

## TDD regression

Initial gap: `LoreBacklinkService.retargetOccurrences` selected every `SceneBeat` in the database despite receiving `projectId`. A retarget from project A could mutate matching links in project B.

Added test:

```text
retarget does not mutate another project
```

RED result before production fix:

```text
Expected: <1>
Actual: <2>
```

The extra mutation came from the fixture scene belonging to project 2.

Minimal fix in `lib/features/bible/application/lore_backlink_service.dart`:

1. select stories by `projectId`;
2. select scenes belonging to those stories;
3. select scene beats whose `sceneId` belongs to those scenes;
4. keep existing link-only retarget behavior.

## Focused verification

Command:

```text
flutter test test/features/story/lore_backlinks_test.dart test/features/story/lore_link_autocomplete_test.dart
```

Result:

```text
All tests passed! — 31 tests
```

Scoped analyzer:

```text
dart analyze lib/features/bible/application/lore_backlink_service.dart test/features/story/lore_backlinks_test.dart
```

Result:

```text
No issues found!
```

Diff gate:

```text
git diff --check
```

Result: PASS.

## Open gaps

1. (Closed 2026-09-02, commit 054e274) Unified catalog now covers Character, Location/Environment, Faction, species/tech/power, and bible lore in one project-scoped application contract.
2. Global search UI, result navigation, and source-to-target reference opening are not fully proven here.
3. Rename safety is proven for link retargeting, but not yet wired to every entity rename command and every persisted source type.
4. Native Windows interaction remains unverified.
5. Full project gates were not rerun after this focused change; prior full gates are historical evidence only.

## Decision

`145.29 Lore Linking and Search` berstatus **PARTIAL**. Link syntax, deterministic suggestions, keyboard flow, broken/ambiguous reporting, lore creation, rename-safe segment editing, and project-scoped retargeting are live and covered by 31 passing focused tests. The project-scope mutation bug was fixed through a RED → GREEN regression. The unified cross-domain catalog is now proven (2026-09-02, commit 054e274: Characters/Environments/Factions joined the live catalog with 3 new RED-verified tests). Cross-workspace search UI, universal rename wiring, and native proof remain open.

Next canonical step: `145.30 Autosave Snapshot and Crash Recovery`.

## Changed paths owned by this audit

- `lib/features/bible/application/lore_backlink_service.dart`
- `test/features/story/lore_backlinks_test.dart`
- `docs/audits/lore-linking-and-search.md`
- `docs/sprints/sprint-145-product-scope-reset-mvp-recovery.md`

No schema, migration, route, credential, or destructive storage operation was performed.
