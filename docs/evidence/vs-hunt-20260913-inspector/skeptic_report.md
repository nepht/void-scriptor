# Skeptic Review Report: Inspector Scope

---
**BUG-01** | Original: 5 pts
- **Counter-argument:** None. The observation is entirely accurate. `CharacterInspector` invokes `InspectorBody(name: characterId, ...)` where `characterId` is the raw UUID string rather than querying the database for the character's display name.
- **Evidence:** `lib/features/inspector/presentation/inspectors/character_inspector.dart`:
  ```dart
  InspectorBody(name: characterId, type: 'Character', sections: const []),
  ```
- **Confidence:** 100%
- **Risk calc:** EV = (100% x 5) - (0% x 10) = +5.0
- **Decision:** ACCEPT
---

---
**BUG-02** | Original: 5 pts
- **Counter-argument:** None. When `wardrobeInspectorProvider` is loading or returns null, `WardrobeInspector` falls back to rendering a container with `Text(wardrobeId, style: VoidTypography.title)`, exposing the raw UUID string directly in the UI without any loading indicator or error message.
- **Evidence:** `lib/features/inspector/presentation/inspectors/wardrobe_inspector.dart`:
  ```dart
    if (data == null) {
      return Container(
        color: context.palette.panel,
        padding: const EdgeInsets.all(16),
        child: Text(wardrobeId, style: VoidTypography.title),
      );
    }
  ```
- **Confidence:** 100%
- **Risk calc:** EV = (100% x 5) - (0% x 10) = +5.0
- **Decision:** ACCEPT
---

---
**BUG-03** | Original: 5 pts
- **Counter-argument:** None. `WeaponInspector` uses `data?.name ?? weaponId` to render the title, which silently falls back to the raw UUID string while loading or when data is null.
- **Evidence:** `lib/features/inspector/presentation/inspectors/weapon_inspector.dart`:
  ```dart
            Text(
              data?.name ?? weaponId,
              style: TextStyle(
                color: context.palette.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
  ```
- **Confidence:** 100%
- **Risk calc:** EV = (100% x 5) - (0% x 10) = +5.0
- **Decision:** ACCEPT
---

---
**BUG-04** | Original: 10 pts
- **Counter-argument:** None. `RelationSection` awaits `confirmRelationDeletion` (and `getById`), but unlike `SupportRelationshipSection`, it does not re-validate that the active project session has remained unchanged across the async gap before executing the deletion command against the database session, risking cross-project mutations if a project switch occurs.
- **Evidence:** `lib/features/inspector/presentation/widgets/relation_section.dart`:
  ```dart
                              final confirmed = await confirmRelationDeletion(
                                context,
                                targetName: item.assetName,
                              );
                              if (!confirmed || !context.mounted) return;
                              final session = ref
                                  .read(projectSessionProvider)
                                  .valueOrNull;
                              if (session == null) return;
                              final repository = RelationRepositoryImpl(
                                database: session.database,
                              );
  ```
- **Confidence:** 100%
- **Risk calc:** EV = (100% x 10) - (0% x 20) = +10.0
- **Decision:** ACCEPT
---

---
**BUG-05** | Original: 1 pt
- **Counter-argument:** The wildcard switch branch (`_ => const EmptyInspector()`) in `InspectorResolver` is standard Dart pattern matching and exhaustiveness handling for asset types. Falling back to `EmptyInspector` when encountering unhandled or future asset types is robust and expected UI behavior, not a defect or type-safety flaw.
- **Evidence:** `lib/features/inspector/presentation/inspector_resolver.dart`:
  ```dart
        _ => const EmptyInspector(),
  ```
- **Confidence:** 95%
- **Risk calc:** EV = (95% x 1) - (5% x 2) = 0.95 - 0.10 = +0.85
- **Decision:** DISPROVE
---

---
**BUG-06** | Original: 5 pts
- **Counter-argument:** None. In `SupportRelationshipSection`, `_load()` performs asynchronous fetches (`repository.listSupports` and `session.database.assetDao.getAllAssets()`) without checking whether the active project session changed during the async gap before calling `setState`, potentially applying stale data from a previous session after a project switch.
- **Evidence:** `lib/features/inspector/presentation/widgets/support_relationship_section.dart`:
  ```dart
    try {
      final supports = await repository.listSupports(widget.assetId);
      final assets = await session.database.assetDao.getAllAssets();
      if (!mounted) return;
      setState(() {
        _supports = supports;
        _loadedSessionId = session.manifest.id;
  ```
- **Confidence:** 100%
- **Risk calc:** EV = (100% x 5) - (0% x 10) = +5.0
- **Decision:** ACCEPT
---

**SUMMARY:**
- Bugs disproved: 1 (total points claimed: 1)
- Bugs accepted as real: 5
- Your final score: +1

**ACCEPTED BUG LIST:**
- BUG-01
- BUG-02
- BUG-03
- BUG-04
- BUG-06
