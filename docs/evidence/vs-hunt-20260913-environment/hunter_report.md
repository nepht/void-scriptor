# Adversarial Bug Hunt Report: Region `lib/features/environment`
- **Target Repo:** `D:\VoidScriptor\void_scriptor_multiplatform`
- **Branch:** master
- **HEAD Commit:** 902bc57
- **Scope Files:** 7 files in `lib/features/environment/`

---
**BUG-001** | Severity: Medium | Points: 5
- **File:** `lib/features/environment/application/create_environment_service.dart`
- **Line(s):** 29-94
- **Category:** data-integrity
- **Claim:** Database transaction commits before filesystem directory creation, risking orphaned database records if disk I/O fails.
- **Evidence:**
```dart
      await database.transaction(() async {
        await database
            .into(database.assets)
            .insert(...);
        // ... other database inserts
      });

      for (final folder in [
        'references/exterior',
        'references/interior',
        'references/materials',
        'references/lighting',
        'references/weather',
        'references/continuity',
        'generated',
        'thumbnails',
        'exports',
      ]) {
        await Directory(
          '${environmentDirectory.path}${Platform.pathSeparator}$folder',
        ).create(recursive: true);
      }
```
---

---
**BUG-002** | Severity: Medium | Points: 5
- **File:** `lib/features/environment/presentation/environment_workspace_screen.dart`
- **Line(s):** 167-194, 210-216
- **Category:** logic
- **Claim:** Environment workspace screen renders hardcoded stub data for lighting, weather, and continuity cards instead of loading actual profile data from the database.
- **Evidence:**
```dart
class _EnvironmentLightingCard extends StatelessWidget {
  const _EnvironmentLightingCard();
  @override
  Widget build(BuildContext context) => const _EnvironmentCard(
    title: 'LIGHTING',
    child: Column(
      children: [
        _PropertyRow('Time', 'Noon'),
        _PropertyRow('Key', '—'),
        _PropertyRow('Fog', '0.0'),
      ],
    ),
  );
}
```
---

---
**BUG-003** | Severity: Medium | Points: 5
- **File:** `lib/features/environment/domain/scene_environment_context.dart`
- **Line(s):** 1-15
- **Category:** type-safety
- **Claim:** Domain class name `SceneEnvironmentContext` conflicts directly with Drift's generated database data class `SceneEnvironmentContext`, creating naming ambiguity and potential import collisions.
- **Evidence:**
```dart
class SceneEnvironmentContext {
  const SceneEnvironmentContext({
    required this.environmentId,
    this.zoneId,
    this.lightingProfileId,
    this.weatherProfileId,
    this.continuityStateId,
  });
```
---

---
**BUG-004** | Severity: Low | Points: 1
- **File:** `lib/features/environment/presentation/environment_workspace_screen.dart`
- **Line(s):** 157-161
- **Category:** edge-case
- **Claim:** Property rows in the environment info card evaluate against empty string defaults rather than null, causing blank values (`''`) to be rendered instead of fallback dash (`'—'`).
- **Evidence:**
```dart
        _PropertyRow('Type', model?.environmentType ?? '—'),
        _PropertyRow('Location', model?.location ?? '—'),
        _PropertyRow('Architecture', model?.architecture ?? '—'),
        _PropertyRow('Terrain', model?.terrain ?? '—'),
        _PropertyRow('Notes', model?.notes ?? '—'),
```
---

**TOTAL FINDINGS:** 4
**TOTAL SCORE:** 16
