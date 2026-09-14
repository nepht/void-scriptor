# Adversarial Bug Hunt — Skeptic Report

Scope: `lib/features/bible/domain` and `lib/features/bible/presentation` (14 non-generated Dart files). Hunter findings independently checked against the reported source, callers/composition, tests, sprint documentation, and project-session/router code.

Scoring follows the skeptic reference: each finding is worth 5 points; a disproof is permitted only above 67% confidence. For accepted findings, the reference's ACCEPT decision is recorded as `CONFIRMED` in the machine-facing verdict below.

---
**BUI-BUG-01** | Original: 5 pts | Severity: Medium | Verdict: **CONFIRMED**
- **Counter-argument:** None sufficient to disprove the finding. The control state is visibly wired to the tabs/dropdown selection indicator, but not to the content selection/rendering.
- **Evidence:** In `project_bible_workspace_screen.dart`, `_selectedSection` is initialized at line 37. The narrow dropdown updates only that integer (lines 58–67), and desktop chips receive it only as `selectedIndex` while their callback updates it (lines 70–73). The build then unconditionally emits `_OverviewGrid`, `_FactionsSection`, `_RelationMapSection`, and the canon/conflict/timeline cards (lines 76–102). There is no conditional, scroll target, route action, or descendant callback carrying the selected section. The private child widgets are instantiated directly and cannot read the parent State's private field through an inherited widget or callback.
- The focused test also supports the observed contract: `factions_editor_ui_test.dart` taps the `Factions` ChoiceChip (lines 81–83 and 98–100), while the Factions card is already always rendered; the narrow test explicitly comments that the card is “always rendered below the overview grid” (lines 161–164). This verifies presentation, not section navigation.
- **Confidence:** 99%
- **Risk calc:** EV is not applicable because this is an acceptance, not a disproof.
- **Decision:** ACCEPT / CONFIRMED

---
**BUI-BUG-02** | Original: 5 pts | Severity: Medium | Verdict: **CONFIRMED**
- **Counter-argument:** The sprint documentation describes this as a “first responsive integration slice,” and says data editors/inspectors and full conflict orchestration are follow-up work. That establishes scope limitations, but does not establish that these overview values are an intentional placeholder contract or that displaying them as current project metrics is correct.
- **Evidence:** `_OverviewGrid.build` defines a `const cards` list with `value: 'Void Universe'`, `value: '0'`, `value: '0 entities'`, and `value: '0'` (`project_bible_workspace_screen.dart`, lines 203–225). Unlike `_TimelineCard` immediately below, which watches `projectSessionProvider` and queries `BibleTimelineRepository.listEras(session.manifest.id)` (lines 327–385), `_OverviewGrid` does not watch a session or query any repository. Thus populated Bible entries, entities, or historical events cannot affect these displayed values.
- `docs/sprints/sprint-21-project-bible.md` establishes that the feature has persisted project-scoped Bible entries, factions, timeline eras, historical events, and conflict findings (lines 5–12, 20–27), while its UI section only promises the named sections/cards and responsive layout (lines 52–63). I found no acceptance text documenting `Void Universe` or permanent zero metrics as an intentional placeholder value. The documentation's statement that completeness is follow-up work does not make incorrect dashboard claims safe when the relevant data already exists.
- **Confidence:** 94%
- **Risk calc:** EV is not applicable because this is an acceptance, not a disproof.
- **Decision:** ACCEPT / CONFIRMED

---
**BUI-BUG-03** | Original: 5 pts | Severity: Medium | Verdict: **CONFIRMED**
- **Counter-argument:** A project change may cause other workspace branches to remount, but the reported Bible screen is not keyed by project in either of the router entries, and its two data-bearing descendants have no project identity in their widget configuration. The resolver's project keys for `WorldbuildingBody` do not key `ProjectBibleWorkspaceScreen`.
- **Evidence:** Both Bible route definitions in `lib/app/routing/app_router.dart` construct `const ProjectBibleWorkspaceScreen()` (lines 129–132 and 446–449), with no project-dependent `ValueKey`. The workspace resolver's project-key pattern is explicitly present for worldbuilding: `WorldbuildingBody(key: ValueKey('wb-${selection.projectId ?? ''}'), ...)` (workspace_resolver.dart lines 205–211 and 221–225), but no such wrapper exists for the Bible route.
- In `project_bible_workspace_screen.dart`, `_FactionsSectionState.initState` calls `_reload()` (lines 403–407), and `_reload` captures `ref.read(projectSessionProvider).valueOrNull`, then queries the captured database/project ID (lines 409–417). Its listener only reloads when `previous?.valueOrNull == null && next.valueOrNull != null` (lines 437–448). `_RelationMapSectionState` has the same init/load behavior (lines 657–672) and the same null-to-non-null-only listener (lines 674–685). A direct A-to-B provider transition therefore leaves the old state/list result in place and does not trigger either reload; the next project can be shown with A's cached data.
- The session controller supports switching/opening a project and separately closing a session (`project_persistence_providers.dart`, provider/controller implementation; close is used by project-management and restore flows). Nothing in the Bible route composition guarantees disposal before a non-null-to-non-null session update. The report is therefore reachable in the live composition, even if some particular project-picker flow happens to close first.
- **Confidence:** 91%
- **Risk calc:** EV is not applicable because this is an acceptance, not a disproof.
- **Decision:** ACCEPT / CONFIRMED

---
**BUI-BUG-04** | Original: 5 pts | Severity: Medium | Verdict: **CONFIRMED**
- **Counter-argument:** `WorldImageCard` is a `ConsumerStatefulWidget`, so it rebuilds when its parent `FactionImageCard` or `TimelineEraImageCard` rebuilds from a changed session. However, rebuild alone does not reload `_path`; the state is retained because the child has no project-dependent key and `didUpdateWidget` compares only `entityId`.
- **Evidence:** `world_image_card.dart` stores the loaded path in `_path` and invokes `_reload()` only in `initState` (lines 45–53) or when `oldWidget.entityId != widget.entityId` (lines 55–59). `_reload()` reads from the current `widget.readImage` callback (lines 61–73), so failing to call it after callback replacement preserves the prior path.
- The two real parents close over the current session: `FactionImageCard.build` watches `projectSessionProvider` and passes `read(session.database, id)` plus an importer using `session.database`/`session.package` (faction_image_card.dart lines 26–37). `TimelineEraImageCard` does the equivalent (lines 25–36). Their `WorldImageCard` children have only the entity ID as identifying data and no `ValueKey` containing project identity. On an A-to-B switch with the same entity ID, callbacks can therefore change while `entityId` remains equal, and the retained state can display A's image. `hasSession` is watched only for the import button (world_image_card.dart lines 101–103), not for image reload.
- **Confidence:** 96%
- **Risk calc:** EV is not applicable because this is an acceptance, not a disproof.
- **Decision:** ACCEPT / CONFIRMED

---

**SUMMARY:**
- Bugs disproved: 0 (total points claimed: 0)
- Bugs accepted as real: 4
- Your final score: 20 net points

**ACCEPTED BUG LIST:**
- BUI-BUG-01 — Medium
- BUI-BUG-02 — Medium
- BUI-BUG-03 — Medium
- BUI-BUG-04 — Medium

SKEPTIC VERDICTS: confirmed=4 disproved=0 unsure=0
