# Adversarial Bug Hunt Report: Inspector Scope

---
**BUG-01** | Severity: Medium | Points: 5
- **File:** `lib/features/inspector/presentation/inspectors/character_inspector.dart`
- **Line(s):** 15
- **Category:** data-integrity
- **Claim:** CharacterInspector passes the raw characterId UUID string as the name parameter to InspectorBody instead of loading and displaying the character's actual display name.
- **Evidence:** 
```dart
      InspectorBody(name: characterId, type: 'Character', sections: const []),
```
---

---
**BUG-02** | Severity: Medium | Points: 5
- **File:** `lib/features/inspector/presentation/inspectors/wardrobe_inspector.dart`
- **Line(s):** 72-78
- **Category:** error-handling
- **Claim:** WardrobeInspector silently falls back to displaying the raw wardrobeId UUID when wardrobeInspectorProvider is loading or returns null, with no loading or error indicator.
- **Evidence:** 
```dart
    if (data == null) {
      return Container(
        color: context.palette.panel,
        padding: const EdgeInsets.all(16),
        child: Text(wardrobeId, style: VoidTypography.title),
      );
    }
```
---

---
**BUG-03** | Severity: Medium | Points: 5
- **File:** `lib/features/inspector/presentation/inspectors/weapon_inspector.dart`
- **Line(s):** 66, 75
- **Category:** error-handling
- **Claim:** WeaponInspector silently falls back to displaying the raw weaponId UUID as customs title when weaponInspectorProvider is loading or returns null, with no loading indicator or error message.
- **Evidence:** 
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
---

---
**BUG-04** | Severity: Critical | Points: 10
- **File:** `lib/features/inspector/presentation/widgets/relation_section.dart`
- **Line(s):** 120-138, 182-193
- **Category:** concurrency
- **Claim:** RelationSection performs asynchronous dialog awaits without re-validating project session consistency afterwards, risking database operations against a stale or switched project session.
- **Evidence:** 
```dart
                            onPressed: () async {
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
---

---
**BUG-05** | Severity: Low | Points: 1
- **File:** `lib/features/inspector/presentation/inspector_resolver.dart`
- **Line(s):** 33-44
- **Category:** type-safety
- **Claim:** InspectorResolver falls back to EmptyInspector via a wildcard switch branch for unhandled asset types without logging or indication.
- **Evidence:** 
```dart
        _ => const EmptyInspector(),
```
---

---
**BUG-06** | Severity: Medium | Points: 5
- **File:** `lib/features/inspector/presentation/widgets/support_relationship_section.dart`
- **Line(s):** 108-153
- **Category:** concurrency
- **Claim:** SupportRelationshipSection _load method updates state asynchronously without verifying if the project session changed during the fetch, potentially mixing or overwriting state across project switches.
- **Evidence:** 
```dart
    try {
      final supports = await repository.listSupports(widget.assetId);
      final assets = await session.database.assetDao.getAllAssets();
      if (!mounted) return;
      setState(() {
        _supports = supports;
        _loadedSessionId = session.manifest.id;
```
---

**TOTAL FINDINGS:** 6
**TOTAL SCORE:** 31
