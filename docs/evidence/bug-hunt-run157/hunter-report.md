# Hunter Report — Void Scriptor narrative-assignment / support-relationship region
Repo: D:\VoidScriptor\void_scriptor_multiplatform — branch master, HEAD 2317894d. Read-only hunt.
Scope: all 6 in-scope files read fully; related files read for tracing only (explorer_panel.dart, project_database.dart, character_repository_impl.dart, workspace_character_deletion_service.dart, project_persistence_providers.dart, character_mode_controller.dart, portable_project_service.dart, asset_dao.dart, create_story_service.dart, tests). No code executed, no edits, no network.

---

**BUG-01** | Severity: High | Points: 10
- **File:** lib/features/character/presentation/widgets/narrative_assignment_card.dart
- **Line(s):** 82–109 (root), with 61–71 (didUpdateWidget), 147–154 (_selectNovel), 111–145 (_save)
- **Category:** concurrency
- **Claim:** `_loadFor` has no staleness/request-token guard, so a stale in-flight load (after character switch, rapid novel switch, or project switch) can land last and populate the editor with another character's/novel's/project's assignment, which a subsequent Save then persists under the wrong coordinates.
- **Evidence:** `final assignment = await repo.getAssignment(novelWorkspaceId: novel.id, characterId: widget.characterId); if (!mounted) return; setState(() { _roles = assignment?.roles ?? ...; _loadedForCurrentNovel = true; ... });` — the only guard is `mounted`, which is still true after `didUpdateWidget` swaps `widget.characterId` (lines 63–70 reset `_roles`/`_loadedForCurrentNovel` but cannot cancel the awaited future). Two overlapping `_loadFor` calls complete in arbitrary order; the loser overwrites the winner. Because `_loadedForCurrentNovel` is then `true` while `_selectedNovel` points at the new novel, `_save()` (line 111) writes the stale `_roles`/`_importance`/`_pov` via `NarrativeAssignment(novelWorkspaceId: novel.id, characterId: widget.characterId, ...)` — a genuine cross-character/cross-novel data corruption path, not just a display flicker.

---

**BUG-02** | Severity: Medium | Points: 5
- **File:** lib/features/workspaces/application/narrative_assignment_repository.dart
- **Line(s):** 126–145
- **Category:** data-integrity
- **Claim:** `deleteForCharacter` — documented as "Used by character deletion cleanup" — has zero production callers, so deleting a character leaves orphaned narrative assignments and support rows (as source AND as supported target) in both tables forever.
- **Evidence:** `/// Removes all narrative rows of one character ... Used by character deletion cleanup;` `Future<void> deleteForCharacter(String characterId) async {`. Repo-wide grep for `deleteForCharacter` matches only this definition and `test/features/workspaces/narrative_assignment_persistence_test.dart:295`. The real deletion path (`lib/features/character/data/character_repository_impl.dart` `deleteCharacter`, lines 102–117) removes references, modes, identity profiles, and the asset but never calls into `NarrativeAssignmentRepository`. Orphans surface later as raw-UUID rows rendered via the fallback `_characterNames[support.supportedId] ?? support.supportedId` (support_relationship_section.dart:172–173).

---

**BUG-03** | Severity: Medium | Points: 5
- **File:** lib/features/inspector/presentation/widgets/support_relationship_section.dart
- **Line(s):** 211–236
- **Category:** error-handling (data loss)
- **Claim:** `_editSupport` performs a non-transactional remove-then-save; if `removeSupport` succeeds and the subsequent `saveSupport` throws, the relationship row is permanently lost.
- **Evidence:** `await repository.removeSupport(sourceCharacterId: support.sourceCharacterId, supportedId: support.supportedId, storyNovelWorkspaceId: support.storyNovelWorkspaceId); ... await repository.saveSupport(result);` — the delete and insert are two independent repository calls, not wrapped in `database.transaction`. The comment admits the branch is for coordinate changes ("Coordinates changed (picker locked, defensive)"), so today it is near-dead code, but any state desync (e.g. the stale-dialog scenario in BUG-04) or a save failure after the delete destroys the persisted row with no recovery path beyond manual re-entry.

---

**BUG-04** | Severity: Medium | Points: 5
- **File:** lib/features/inspector/presentation/widgets/support_relationship_section.dart
- **Line(s):** 194–209, 211–236, 238–281
- **Category:** concurrency
- **Claim:** `_addSupport`, `_editSupport` and `_deleteSupport` capture the session-bound `NarrativeAssignmentRepository` before awaiting the modal dialog, so switching projects while a dialog is open makes the save/delete write into the previous project's database.
- **Evidence:** `final repository = _repository(); if (repository == null || !mounted) return; final result = await _showEditDialog(repository, null); ... await repository.saveSupport(result);` — `repository` holds the old `session.database` and old `projectId`; nothing re-validates the session after the await (contrast `_repository()` which re-reads `projectSessionProvider` on every call). Same pattern in `_editSupport` and `_deleteSupport` (repository captured before `showDialog<bool>` confirm). The section reloads for the new project (build guard lines 113–123), so the user is looking at project B while the write lands in project A — cross-project contamination.

---

**BUG-05** | Severity: Medium | Points: 5
- **File:** lib/features/character/presentation/widgets/narrative_assignment_card.dart (21–30) and lib/features/inspector/presentation/widgets/support_relationship_section.dart (19–29)
- **Line(s):** narrative_assignment_card.dart 21–30; support_relationship_section.dart 19–29
- **Category:** other (stale derived state)
- **Claim:** Both novel-option providers derive from `projectAssetsProvider` / a raw `getAllAssets()` snapshot that is not invalidated when a novel is created, so a newly created novel is missing from the "Story (novel)" dropdowns of the Narrative Assignment card and the Add-Support dialog until some unrelated action rebuilds the asset provider graph.
- **Evidence:** `final assets = await ref.watch(projectAssetsProvider.future); return assets.where((asset) => asset.type == 'story')...` (card) and `final assets = await session.database.assetDao.getAllAssets(); return assets.where((asset) => asset.type == 'story')...` (section). The story-creation path (explorer_panel.dart:1032–1049, scene_workspace_screen.dart:139–159, workspace_resolver.dart:110–114) invalidates only `storyExplorerProvider(projectId)`; repo-wide grep finds no `invalidate(narrativeNovelOptionsProvider)`, `invalidate(supportNovelOptionsProvider)` or `invalidate(projectAssetsProvider)` on story creation. Neither provider is autoDispose, so the stale list persists for the session.

---

**BUG-06** | Severity: Medium | Points: 5
- **File:** lib/features/workspaces/application/narrative_assignment_repository.dart
- **Line(s):** 182–202 (also 217–222)
- **Category:** error-handling
- **Claim:** `_assignmentFromRow` throws `ArgumentError` on any unknown role/importance/POV wire token, so a single corrupt row makes `listAssignments()` fail wholesale, and the explorer character filter then silently behaves as if the project had no assignments at all (a role filter collapses the character list to zero).
- **Evidence:** `.map((token) => token.trim())...map(domain.NarrativeRole.fromWire).toSet();` — `NarrativeRole.fromWire` is `throw ArgumentError.value(value, 'roles', 'Unknown narrative role');`. The read path (`listAssignments`, lines 62–67) has no per-row tolerance, and the consumer drops the error: explorer_panel.dart:1301–1313 uses `ref.watch(explorerNarrativeAssignmentsProvider).valueOrNull` then `filter.matchesCharacter(characterId: item.assetId, assignments: assignments ?? const [])` — with a role filter active, `own.any(...)` over an empty list is false for every character. The fail-loud policy is fine for `getAssignment` (card catches it), but the list path turns one bad token into a project-wide silent filter failure. `roleTokensToRoles` (line 221) has the same strictness.

---

**BUG-07** | Severity: Low | Points: 1
- **File:** lib/features/inspector/presentation/widgets/support_relationship_section.dart
- **Line(s):** 60–71 (vs 158–164)
- **Category:** edge-case
- **Claim:** When the project session is still loading, `_load()` stores `_supports = const []`, so the section renders "No support relationships yet" — conflating not-ready with empty, exactly the fake-empty failure its own comment forbids for load errors.
- **Evidence:** `if (session == null || !mounted) { if (mounted) { setState(() { _supports = const []; ...` while build renders `else if (supports == null) Text('Loading...') ... else if (supports.isEmpty) Text('No support relationships yet')`. The build guard (lines 113–123) later self-corrects when the session appears, but until then a real relationships list is misrepresented as "none yet".

---

**BUG-08** | Severity: Low | Points: 1
- **File:** lib/features/character/presentation/widgets/narrative_assignment_card.dart
- **Line(s):** 280–288 (with 102–108)
- **Category:** error-handling
- **Claim:** After a load failure the card shows "Could not load assignment: …" together with a permanent "Loading assignment…" line, because the error branch leaves `_loadedForCurrentNovel` false and the editor branch treats that as loading.
- **Evidence:** `catch (error) { ... setState(() { _error = '$error'; _loading = false; }); }` (no `_loadedForCurrentNovel` change) and `if (_loading || !_loadedForCurrentNovel) const Padding(... Text('Loading assignment...'))` — with `_loading` false and `_loadedForCurrentNovel` false, both the error text and "Loading assignment..." render forever with no retry control. Related: `didUpdateWidget` (61–71) never clears `_error`, so a stale error from the previous character persists into the next selection.

---

**BUG-09** | Severity: Low | Points: 1
- **File:** lib/features/character/presentation/widgets/narrative_assignment_card.dart
- **Line(s):** 82–88
- **Category:** edge-case
- **Claim:** `_loadFor` returns silently when the session/repository is missing, leaving `_loadedForCurrentNovel` false and the card stuck on "Loading assignment..." with no error and no retry.
- **Evidence:** `final repo = _repository(); if (repo == null) return; setState(() { _loading = true; ... })` — the early return happens after `_selectNovel` already cleared `_loadedForCurrentNovel`, so the UI's `!_loadedForCurrentNovel` branch shows an eternal loading state with nothing pending.

---

**BUG-10** | Severity: Low | Points: 1
- **File:** lib/features/workspaces/domain/narrative_assignment.dart
- **Line(s):** 303–318
- **Category:** logic
- **Claim:** `SupportRelationship.copyWith` can never clear `purpose` or `separationReason` back to null, so a recorded separation reason (or purpose) is impossible to remove through the copy API — the "keep current value" sentinel collides with the legitimate null value.
- **Evidence:** `SupportRelationship copyWith({... String? purpose, String? separationReason,}) => SupportRelationship(... purpose: purpose ?? this.purpose, separationReason: separationReason ?? this.separationReason,);` — passing `purpose: null` (the only way to express "clear it") keeps the old value.

---

**BUG-11** | Severity: Low | Points: 1
- **File:** lib/features/workspaces/domain/narrative_assignment.dart
- **Line(s):** 139–153
- **Category:** type-safety
- **Claim:** `NarrativeAssignment.fromJson` hard-casts role entries to `String` and routes them through strict `fromWire`, so any malformed or unknown token in stored/exported JSON throws and aborts the whole decode with no recovery, and the method currently has no production caller to justify the strictness.
- **Evidence:** `rawRoles.map((role) => NarrativeRole.fromWire(role as String)).toSet()` plus `novelWorkspaceId: json['novel_workspace_id'] as String` — a single bad element (`roles: ["protagonist", 3]` or a retired wire token) throws `ArgumentError`/`TypeError` for the entire assignment. Repo grep shows `NarrativeAssignment.fromJson` is unreferenced in lib/ (latent until adopted).

---

**BUG-12** | Severity: Low | Points: 1
- **File:** lib/features/workspaces/domain/narrative_character_filter.dart
- **Line(s):** 34–40
- **Category:** performance
- **Claim:** `matchesCharacter` linearly scans the full assignment iterable for every character, making the explorer filter O(characters × assignments) on every rebuild with no pre-grouping by characterId.
- **Evidence:** `final own = assignments.where((assignment) => assignment.characterId == characterId).toList(growable: false);` — called per character from explorer_panel.dart:1311 inside `characters.where(...)`, so a project with C characters and A assignments performs C×A comparisons per rebuild of the panel.

---

**BUG-13** | Severity: Low | Points: 1
- **File:** lib/features/workspaces/application/narrative_assignment_repository.dart
- **Line(s):** 87–98
- **Category:** logic
- **Claim:** `listSupportsFor` returns rows with no deterministic ordering, unlike its sibling `listSupports` which orders by story then supported id, so reverse-direction views have unstable row order across loads.
- **Evidence:** `listSupports` has `..orderBy([(row) => OrderingTerm.asc(row.storyNovelWorkspaceId), (row) => OrderingTerm.asc(row.supportedId)])` (79–82) while `listSupportsFor` ends at `..where((row) => row.projectId.equals(projectId) & row.supportedId.equals(supportedId)))` with no `orderBy` before `.get()`.

---

**BUG-14** | Severity: Low | Points: 1
- **File:** lib/features/inspector/presentation/widgets/support_relationship_section.dart
- **Line(s):** 283–314 (with 374–416, 492)
- **Category:** edge-case
- **Claim:** `_showEditDialog` opens the Add-Support dialog even when the project has zero story assets or zero other characters, presenting empty dropdowns with a silently disabled Save button and no explanation of what is missing.
- **Evidence:** `novels = await ref.read(supportNovelOptionsProvider.future); final assets = await repository.database.assetDao.getAllAssets(); characters = assets.where(...asset.id != widget.assetId).toList()` — no empty-list guard before `showDialog`; inside `_SupportEditDialog`, `onPressed: _supportedId == null || _novelId == null ? null : _save` simply disables Save. (The Narrative Assignment card handles the analogous case with an explicit "No novels yet" message.)

---

**BUG-15** | Severity: Low | Points: 1
- **File:** lib/features/workspaces/application/narrative_assignment_repository.dart
- **Line(s):** 131–145
- **Category:** error-handling
- **Claim:** `deleteForCharacter` issues its two deletes (assignments, then supports) outside any database transaction, so a failure between them leaves the character half-cleaned with no way to know which half.
- **Evidence:** `await (database.delete(database.characterNarrativeAssignments)..where(...)).go(); await (database.delete(database.characterSupportRelationships)..where(...)).go();` — no `database.transaction(() async {...})` wrapper, unlike other multi-table cleanup in the codebase (e.g. `character_repository_impl.deleteCharacter` lines 103–117).

---

**BUG-16** | Severity: Low | Points: 1
- **File:** lib/features/inspector/presentation/widgets/support_relationship_section.dart
- **Line(s):** 60–98 (with 109–123)
- **Category:** concurrency
- **Claim:** A `_load()` started for the previous project can complete after the session-switch guard resets state, briefly rendering the previous project's relationships and character-name map before the build guard self-corrects and triggers a duplicate reload.
- **Evidence:** `final supports = await repository.listSupports(widget.assetId); final assets = await session.database.assetDao.getAllAssets(); if (!mounted) return; setState(() { _supports = supports; _loadedSessionId = session.manifest.id; ...` — there is no check that the session is still the one captured at line 61, and no request token; the completion path sets `_loadedSessionId` back to the old id, which the build guard (113–123) then detects, clearing and re-fetching — one frame of foreign-project data plus duplicated loads.

---

**BUG-17** | Severity: Low | Points: 1
- **File:** lib/features/inspector/presentation/widgets/support_relationship_section.dart
- **Line(s):** 292–296
- **Category:** other (spec/feature gap)
- **Claim:** The domain documents the supported target as "one character or group" (narrative_assignment.dart:193, 258), but the editor's picker offers only character assets, so group targets cannot be created through the UI and any group `supportedId` can never be produced.
- **Evidence:** `characters = assets.where((asset) => asset.type == 'character' && asset.id != widget.assetId).toList(growable: false);` — only `type == 'character'` assets are eligible; no faction/group source is consulted.

---

**BUG-18** | Severity: Low | Points: 1
- **File:** lib/features/inspector/presentation/widgets/support_relationship_section.dart
- **Line(s):** 179–182
- **Category:** other (cosmetic/consistency)
- **Claim:** Support rows display raw wire tokens ("travel_companion · permanent · active") to the user, while the sibling narrative card maps every enum through label helpers (`roleLabel`/`importanceLabel`/`povLabel`), leaving support vocabulary unwired and inconsistent.
- **Evidence:** `subtitle: Text('${support.type.wireName} · ${support.duration.wireName} · ${support.status.wireName}', ...)` — no `supportTypeLabel`-style mapping exists for `SupportType`/`SupportDuration`/`SupportStatus` anywhere in the file.

---

**BUG-19** | Severity: Low | Points: 1
- **File:** lib/features/workspaces/application/narrative_assignment_repository.dart
- **Line(s):** 221–222
- **Category:** other (dead code)
- **Claim:** Top-level `roleTokensToRoles` is exported but has no production caller — it exists only for the test suite, duplicating `_assignmentFromRow`'s token-decoding logic as a second source of truth.
- **Evidence:** `Set<domain.NarrativeRole> roleTokensToRoles(Set<String> roleTokens) => roleTokens.map(domain.NarrativeRole.fromWire).toSet();` — repo grep for `roleTokensToRoles` matches only this definition and no lib/ call sites.

---

## Cross-cutting notes (traced, no separate verdicts)
- Schema v60 migration (project_database.dart:715–718) is idempotent (`m.createTable` → CREATE TABLE IF NOT EXISTS) and both `onCreate`/`onUpgrade` paths cover the two new tables — no finding.
- Portable export/import rewrites `project_id` on every table having that column (portable_project_service.dart:264–293), covering both new tables — consistent with the roundtrip test.
- `rowSetToken` comma-joining is safe today because only enum wire tokens (comma-free, fixed set) ever enter it; the `trim` on decode tolerates whitespace — no finding.
- Filter AND/OR semantics (narrative_character_filter.dart:41–58) match their documented contract including the `unspecified` = "no explicit value on any assignment" reading — no finding.
- `insertOnConflictUpdate` keyed on the composite PKs gives correct per-row upsert semantics for both tables — no finding.

**TOTAL FINDINGS:** 19
**TOTAL SCORE:** 48
