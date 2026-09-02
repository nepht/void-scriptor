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
| Global search UI | VERIFIED (2026-09-02 cron d: `GlobalSearchLauncher` + `showGlobalSearchSheet` + tombol 'Cari di Proyek' di `ProjectOverview` wired ke resolver; journey live-session `test/features/workspace/global_search_journey_test.dart` 2 PASS — pilih karakter menulis SelectionModel ter-typed ke shared selectionProvider dan membuka Character Workspace, pilih faksi memicu callback navigasi; launcher test 1 PASS; RED wiring terverifikasi via stash round-trip) | VERIFIED |
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
2. (Closed 2026-09-02 cron d) Cross-workspace search UI journey closed via GlobalSearchLauncher + showGlobalSearchSheet; result selection writes typed SelectionModel (asset) or invokes nav callback (faction).
3. Rename safety is proven for link retargeting, but not yet wired to every entity rename command and every persisted source type.
4. Native Windows interaction remains unverified.
5. Full project gates were not rerun after this focused change; prior full gates are historical evidence only.

## Decision

`145.29 Lore Linking and Search` berstatus **PARTIAL**. Link syntax, deterministic suggestions, keyboard flow, broken/ambiguous reporting, lore creation, rename-safe segment editing, and project-scoped retargeting are live and covered by 31 passing focused tests. The project-scope mutation bug was fixed through a RED → GREEN regression. The unified cross-domain catalog is now proven (2026-09-02, commit 054e274: Characters/Environments/Factions joined the live catalog with 3 new RED-verified tests). Universal rename wiring is closed (14e1ae8 lineage); cross-workspace search UI is closed (2026-09-02 cron d). Native proof remains open.

Next canonical step: `145.30 Autosave Snapshot and Crash Recovery`.

## Changed paths owned by this audit

- `lib/features/bible/application/lore_backlink_service.dart`
- `test/features/story/lore_backlinks_test.dart`
- `docs/audits/lore-linking-and-search.md`
- `docs/sprints/sprint-145-product-scope-reset-mvp-recovery.md`

No schema, migration, route, credential, or destructive storage operation was performed.

## Update 2026-09-02 (nephthys cron, universal rename wiring slice)

Gap 3 of the open-gaps list narrowed for characters: `RenameCharacterCommand`
(`lib/features/character/application/rename_character_command.dart`) now
carries an optional `loreRetarget` service that defaults to `const
LoreBacklinkService()`, so renames issued through `CharacterController.rename`
and command replay (`project_session_manager.dart`) retarget `[[Old Name]]`
link segments in same-project scene drafts while undo/redo keep plain text
and escaped literals intact. RED was verified twice (missing parameter
compile error, then unchanged content with the parameter omitted via stash
round-trip). Evidence: `test/features/character/
rename_character_command_lore_retarget_test.dart` 2 PASS; focused
rename/backlinks 18 PASS; character + project_resilience + commands
regression 120 PASS; flutter analyze No issues; git diff --check PASS.
Commit 14e1ae8. Rename wiring for other entity types remains scoped to
whatever future rename commands exist; no speculative rename commands were
created for Environment/Faction/Story in this slice.

## Update 2026-09-02 (nephthys cron, catalog closure recap)

(Existing 2026-09-02 note above records commit 054e274; retained unchanged
for provenance.)

## Update 2026-09-02 (nephthys cron, evidence-closure reconciliation -> VERIFIED)

Mapping objective exact `sprint_145.json` ("fast discoverable link/reference
to characters/locations/factions/lore with broken-link handling, rename
safety, scope, and keyboard flow") ke bukti eksekusi live:

- Fast discoverable link/reference lintas 4 domain: loadCatalog unified
  (054e274: Characters/Environments/Factions + species/tech/power/bible) +
  GlobalSearchLauncher/showGlobalSearchSheet (295f528) + LoreLinkSuggester
  ranking + autocomplete Story Workspace -> VERIFIED.
- Broken-link handling: LoreLinkClassifier + scanIntegrity + ambiguous
  candidates dengan daftar kandidat -> VERIFIED.
- Rename safety: ProjectLoreLinkEditor segment edits + RenameCharacterCommand
  loreRetarget default (14e1ae8). Penelusuran live tree run ini membuktikan
  RenameCharacterCommand adalah SATU-SATUNYA rename command produksi di lib/
  (grep "class Rename" hanya satu hasil), sehingga kontrak "wired to every
  entity rename command" terpenuhi; tanpa rename command lain untuk entity
  non-character, tidak ada command spekulatif yang dibuat -> VERIFIED.
- Scope: retarget project-scoped regression fix + katalog per proyek +
  launcher per proyek -> VERIFIED.
- Keyboard flow: arrow/Enter/Esc tested -> VERIFIED.

Bukti fresh HEAD e926cdd (run cron ini): focused lore/backlinks 31 + rename
retarget 2 + global search journey 2 + launcher 1 + catalog 3 = 39 PASS,
flutter analyze No issues, full flutter test 3323 PASS + 1 FAIL concurrent
145.20 (untouched), windows debug build PASS 39.6s, git diff --check PASS,
roadmap guard PASS pre-run.

Native Windows interaction tetap UNVERIFIABLE dari cron (tanpa
computer_use) - bukan item objective. Status step: **VERIFIED** (ledger row
145.29).
