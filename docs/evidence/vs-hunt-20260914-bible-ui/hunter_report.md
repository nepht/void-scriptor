# Adversarial Bug Hunt — Hunter Report

Scope: `lib/features/bible/domain` and `lib/features/bible/presentation` (14 non-generated Dart files)

---
**BUI-BUG-01** | Severity: Medium | Points: 5
- **File:** `lib/features/bible/presentation/project_bible_workspace_screen.dart`
- **Line(s):** 37, 57-74
- **Category:** logic
- **Claim:** The section tabs/dropdown change a selected-index state that is never used to select, filter, or navigate content, so every section control is functionally inert.
- **Evidence:**
  ```dart
  int _selectedSection = 0;
  ...
  _SectionDropdown(
    value: _projectBibleSections[_selectedSection],
    onChanged: (value) {
      if (value == null) return;
      setState(() {
        _selectedSection = _projectBibleSections.indexOf(value);
      });
    },
  )
  ...
  _SectionTabs(
    selectedIndex: _selectedSection,
    onSelected: (index) =>
        setState(() => _selectedSection = index),
  ),
  ...
  _OverviewGrid(narrow: narrow),
  ...
  const _FactionsSection(),
  ...
  const _RelationMapSection(),
  ...
  const _CanonHealthCard(),
  const _ConflictCard(),
  const _TimelineCard(),
  ```
  The build tree renders the same content regardless of `_selectedSection`; there is no conditional or route action based on the selected value.
---

---
**BUI-BUG-02** | Severity: Medium | Points: 5
- **File:** `lib/features/bible/presentation/project_bible_workspace_screen.dart`
- **Line(s):** 209-225
- **Category:** data-integrity
- **Claim:** The overview dashboard permanently displays zero counts and a hard-coded universe name instead of project data, making the Project Bible summary incorrect whenever the project contains entries or events.
- **Evidence:**
  ```dart
  const cards = [
    _MetricCard(
      label: 'Universe',
      value: 'Void Universe',
      icon: Icons.public,
    ),
    _MetricCard(
      label: 'Canon Entries',
      value: '0',
      icon: Icons.library_books_outlined,
    ),
    _MetricCard(
      label: 'Worldbuilding',
      value: '0 entities',
      icon: Icons.account_tree_outlined,
    ),
    _MetricCard(label: 'Historical Events', value: '0', icon: Icons.history),
  ];
  ```
---

---
**BUI-BUG-03** | Severity: Medium | Points: 5
- **File:** `lib/features/bible/presentation/project_bible_workspace_screen.dart`
- **Line(s):** 400-417, 441-447, 654-672, 678-684
- **Category:** data-integrity
- **Claim:** The factions and relationship-map sections do not reload when the active project changes directly from one non-null session to another, so they can show data belonging to the previously open project.
- **Evidence:**
  ```dart
  final factions = await FactionRepository(
    session.database,
  ).listForProject(session.manifest.id);
  ...
  ref.listen<AsyncValue<ProjectSession?>>(projectSessionProvider, (
    previous,
    next,
  ) {
    if (previous?.valueOrNull == null && next.valueOrNull != null) {
      _reload();
    }
  });
  ```
  and:
  ```dart
  final entries = await const CharacterRelationMapService().mapForProject(
    session.database,
    projectId: session.manifest.id,
  );
  ...
  ref.listen<AsyncValue<ProjectSession?>>(projectSessionProvider, (
    previous,
    next,
  ) {
    if (previous?.valueOrNull == null && next.valueOrNull != null) {
      _reload();
    }
  });
  ```
  Both listeners only react to `null -> non-null`; a `project A -> project B` transition is ignored. Existing `_factions`/`_entries` values are not cleared or replaced until another qualifying transition.
---

---
**BUI-BUG-04** | Severity: Medium | Points: 5
- **File:** `lib/features/bible/presentation/widgets/world_image_card.dart`
- **Line(s):** 55-59, 61-73, 101-104
- **Category:** data-integrity
- **Claim:** A world-image card reloads only when its entity ID changes, not when its injected database/session callbacks change, allowing an old project's image to remain displayed for the same entity ID after a project switch.
- **Evidence:**
  ```dart
  @override
  void didUpdateWidget(WorldImageCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entityId != widget.entityId) _reload();
  }
  ```
  and:
  ```dart
  final hasSession = ref.watch(projectSessionProvider).valueOrNull != null;
  return VoidCard(
  ```
  The card's `readImage` and `importImage` callbacks are supplied by the parent and close over `session.database`/`session.package` (for example `faction_image_card.dart` lines 27-37), but callback/session changes do not trigger `_reload()` when `entityId` is unchanged.
---

TOTAL FINDINGS: 4
TOTAL SCORE: 20
