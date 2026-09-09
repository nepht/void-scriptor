# HUNTER REPORT — run165 adversarial bug hunt (Void Scriptor, workspace-switch region)

- Hunt ID: void-scriptor-hunt-20260910 (cron run165)
- Target: D:\VoidScriptor\void_scriptor_multiplatform, branch master, HEAD 51ca455 (dirty theme region excluded, untouched)
- Scope: lib/features/workspace/** (5 files: global_search_launcher.dart, workspace_section_controller.dart, global_search_sheet.dart, workspace_panel.dart, workspace_resolver.dart)
- Method: all 5 in-scope files read fully; supporting reads (selection_controller, selection_model, asset_type, explorer_panel recovery provider, desktop shell callsites) to verify cross-file claims. Read-only.

---

**BUG-01** | Severity: Medium | Points: 5
- **File:** lib/features/workspace/presentation/global_search_sheet.dart
- **Line(s):** 56–63 (button at 115)
- **Category:** concurrency / data-integrity
- **Claim:** Overlapping `_runSearch` calls can resolve out of order, so an older query's results overwrite a newer query's results in the sheet.
- **Evidence:**
```dart
Future<void> _runSearch() async {
  final hits = await widget.launcher.search(
    _controller.text,
    projectId: widget.projectId,
  );
  if (!mounted) return;
  setState(() => _hits = hits);
}
```
No request token/sequence guard exists; `mounted` is the only check. Two rapid "Cari" presses (button stays enabled during flight) with different latencies let the stale response land last.

---

**BUG-02** | Severity: Medium | Points: 5
- **File:** lib/features/workspace/presentation/global_search_sheet.dart
- **Line(s):** 65–70 (callsites: workspace_resolver.dart 144–152; void_desktop_shell.dart 151–161)
- **Category:** logic / error-handling
- **Claim:** Selecting a faction hit pops the sheet and performs no navigation in any production entry point, because no callsite ever passes `onSelectFaction`; additionally the hit id is `faction.assetId` whose semantics no consumer verifies.
- **Evidence:**
```dart
void _openHit(GlobalSearchHit hit) {
  Navigator.of(context).pop();
  if (hit.assetType == null) {
    widget.onSelectFaction?.call(hit.id, hit.title);
    return;
  }
```
with `onSelectFaction` omitted at the only two production callsites:
```dart
showGlobalSearchSheet(
  sheetContext,
  launcher: GlobalSearchLauncher(database: session.database),
  projectId: session.manifest.id,
);
```
`GlobalSearchHit.id` for factions is `faction.assetId` (launcher line 73), not the faction row id — any future consumer assuming the PK mis-files the selection.

---

**BUG-03** | Severity: Medium | Points: 5
- **File:** lib/features/workspace/presentation/workspace_resolver.dart
- **Line(s):** 110–143
- **Category:** data-integrity / concurrency
- **Claim:** `onCreateNovel` writes three entities and a selection to a `session` captured at callback creation, across multiple awaits (title dialog → createStory → createChapter → createScene), with no re-validation that the captured session is still the active project.
- **Evidence:**
```dart
onCreateNovel: session == null
    ? null
    : (title) async {
        final service = CreateStoryService(
          database: session.database,
          paths: ref.read(projectPathsProvider),
        );
        final storyId = await service.createStory(
          projectId: session.manifest.id,
```
A project switch while the title dialog is open makes these writes hit a closed/detached project's database and leaves a selection pointing at the old project — exactly the draft/datum mis-filing class priority #1 calls out (compare the fixed run157 guard pattern cited at 337b821/6a46c45).

---

**BUG-04** | Severity: Medium | Points: 5
- **File:** lib/features/workspace/presentation/workspace_resolver.dart
- **Line(s):** 115–129, 302–307
- **Category:** error-handling / data-integrity
- **Claim:** The novel-creation chain has no try/catch, so a persist failure is silent (no user-visible error, unhandled async exception) and can leave a partially created novel (story without Chapter 1/Scene 1).
- **Evidence:**
```dart
final storyId = await service.createStory(
  projectId: session.manifest.id,
  title: title,
);
final chapterId = await service.createChapter(
  storyId: storyId,
  title: 'Chapter 1',
  chapterNumber: 1,
);
await service.createScene(
```
and in `ProjectOverview._createNovel`:
```dart
await onCreateNovel!(submitted);
if (!context.mounted) return;
ScaffoldMessenger.of(
  context,
).showSnackBar(const SnackBar(content: Text('Novel created.')));
```
An exception in `createStory`/`createChapter` propagates out of the unawaited button callback; the snackbar never shows and the failure is invisible — contrary to the region's own "persist failure visibly" contract.

---

**BUG-05** | Severity: Medium | Points: 5
- **File:** lib/features/workspace/presentation/workspace_resolver.dart
- **Line(s):** 62–64, 99–105, 372–381
- **Category:** logic / edge-case
- **Claim:** A pending creature workspace intent renders the generic `WorldbuildingBody` (with no `assetId` and no creature data) instead of `CreatureWorkspaceScreen`, and creature has no catalog-recovery path, so the user is stranded until they manually re-pick a creature.
- **Evidence:**
```dart
if (session != null && _isWorldbuildingIntent(type)) {
  return WorldbuildingBody(
    key: ValueKey('wb-${session.manifest.id}'),
    assetType: type,
    activeSection: activeSection,
  );
}
```
with
```dart
bool _isWorldbuildingIntent(AssetType? type) => switch (type) {
  AssetType.environment ||
  AssetType.faction ||
  AssetType.timeline ||
  AssetType.creature ||   // creature included here
  ...
```
Intent `(projectId, creature)` persists across project switches (never cleared on switch — verified in selection_controller.dart/project_persistence_providers.dart), and `explorerCatalogRecoveryProvider`'s switch handles only character/story/environment (`default: return;`), so selecting a creature, switching project away and back, lands on the generic worldbuilding overview while `WorkspacePanel`'s header (via `_WorkspacePresentation.forAssetType`) advertises "Creature Workspace".

---

**BUG-06** | Severity: Medium | Points: 5
- **File:** lib/features/workspace/presentation/workspace_resolver.dart
- **Line(s):** 822–882 (write at 869–874)
- **Category:** data-integrity / concurrency
- **Claim:** `_linkCharacterToNovel` persists a novel↔character link after a dialog await without re-validating that `session` is still the active project, so a project switch while the picker dialog is open writes the link into the detached project.
- **Evidence:**
```dart
try {
  await CreateNovelCharacterLinkService(
    links: session.novelCharacterLinks,
    projections: session.workspaceProjections,
  ).create(novelWorkspaceId: novelWorkspaceId, characterAssetId: characterId);
  return session.workspaceProjectionReader.forNovel(novelWorkspaceId);
```
`session` is a parameter captured before `showDialog`; nothing re-checks `session.manifest.id` against the live `projectSessionProvider` before the write.

---

**BUG-07** | Severity: Low | Points: 1
- **File:** lib/features/workspace/presentation/workspace_resolver.dart
- **Line(s):** 492–507
- **Category:** error-handling / edge-case
- **Claim:** `_createFaction` selects the freshly created faction after an await without re-validating the project, so a project switch during creation clears the selection (guard in `SelectionController.select`'s intent write still fires for the old project) and the user sees no result of their action.
- **Evidence:**
```dart
} catch (_) {
  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Faksi gagal dibuat. Coba lagi.')),
  );
}
...
ref
    .read(selectionProvider.notifier)
    .select(
      SelectionModel(
        assetId: faction.assetId,
        assetType: AssetType.faction,
        projectId: session.manifest.id,
      ),
    );
```
No `session.manifest.id == current` re-check after `await const CreateFactionService().create(...)`.

---

**BUG-08** | Severity: Low | Points: 1
- **File:** lib/features/workspace/presentation/global_search_sheet.dart
- **Line(s):** 20–28, 46–63
- **Category:** data-integrity / edge-case
- **Claim:** The search sheet is a key-less modal holding `launcher`/`projectId` as constructor state with no watch on the session, so if the session object changes while it is mounted it keeps searching the previous project's database silently (staleness window bounded by sheet modality, but no rebuild path exists).
- **Evidence:**
```dart
builder: (_) => _GlobalSearchSheet(
  launcher: launcher,
  projectId: projectId,
  onSelectFaction: onSelectFaction,
),
```
`_GlobalSearchSheetState` never reads `projectSessionProvider` and `_runSearch` uses `widget.projectId`/`widget.launcher` verbatim.

---

**BUG-09** | Severity: Low | Points: 1
- **File:** lib/features/workspace/presentation/workspace_resolver.dart
- **Line(s):** 254
- **Category:** logic / edge-case
- **Claim:** The switch fallback for unhandled selection types renders a `const ProjectOverview()` with no callbacks (no Create Novel, no global search) and no key, so a search-sheet pick of an unhandled Assets row type (e.g. `scene`, `prompt`, `reference` — all producible by `_typeFromStorage`) dead-ends on a bare overview.
- **Evidence:**
```dart
      _ => const ProjectOverview(),
    };
```
versus the wired instance at line 106 which receives `onCreateNovel`/`onOpenGlobalSearch`.

---

**BUG-10** | Severity: Low | Points: 1
- **File:** lib/features/workspace/application/global_search_launcher.dart
- **Line(s):** 67–80
- **Category:** logic
- **Claim:** The faction search branch bypasses the caller's `types` filter, so a filtered search (e.g. characters only) still returns faction hits.
- **Evidence:**
```dart
if (types.isEmpty || types.contains(AssetType.faction)) {
  for (final faction in await factions.listForProject(projectId)) {
```
Every other branch filters via `types.contains(type)` (line 50); this one re-Adds `AssetType.faction` to the accepted set regardless of the requested filter.

---

**BUG-11** | Severity: Low | Points: 1
- **File:** lib/features/workspace/application/global_search_launcher.dart
- **Line(s):** 82–86
- **Category:** logic
- **Claim:** Faction hits never receive a score tie-break distinction beyond lowercase title equality, and the comparator has no id fallback, so case-variant equal titles leave sort order to Dart's unstable sort — non-deterministic result order across runs.
- **Evidence:**
```dart
hits.sort((a, b) {
  final byScore = b.score.compareTo(a.score);
  if (byScore != 0) return byScore;
  return a.title.toLowerCase().compareTo(b.title.toLowerCase());
});
```

---

**BUG-12** | Severity: Low | Points: 1
- **File:** lib/features/workspace/presentation/workspace_panel.dart
- **Line(s):** 22–27
- **Category:** edge-case / data-integrity
- **Claim:** While the session is loading (`projectId == null`), the panel derives the workspace presentation from any live selection — including a selection belonging to another project — showing the wrong workspace header/state during the switch window.
- **Evidence:**
```dart
final workspace = _WorkspacePresentation.forAssetType(
  (selection?.projectId == projectId || projectId == null
          ? selection?.assetType
          : null) ??
      (intent?.$1 == projectId ? intent?.$2 : null),
);
```
`projectId == null` short-circuits the project-compatibility check that the resolver itself enforces at lines 60–61.

---

TOTAL FINDINGS: 12
TOTAL SCORE: 36
