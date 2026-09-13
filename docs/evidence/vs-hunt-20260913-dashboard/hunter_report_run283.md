---
**BUG-01** | Severity: Medium | Points: 5
- **File:** lib/features/dashboard/data/dashboard_repository.dart
- **Line(s):** 11, 31
- **Category:** performance
- **Claim:** The repository fetches all assets across the entire database and filters them in memory rather than querying the database directly by project identifier.
- **Evidence:**
```dart
    final assetsFuture = database.assetDao.getAllAssets();
    ...
    final assets = await assetsFuture;
    ...
      assets: assets.where((asset) => asset.projectId == projectId).length,
```
---
**BUG-02** | Severity: Medium | Points: 5
- **File:** lib/features/dashboard/application/dashboard_snapshot_provider.dart
- **Line(s):** 12-18
- **Category:** error-handling
- **Claim:** The dashboard snapshot future provider lacks explicit error handling or try-catch block when underlying DAO database queries fail.
- **Evidence:**
```dart
final dashboardSnapshotProvider =
    FutureProvider.autoDispose<DashboardSnapshot?>((ref) async {
      final session = ref.watch(projectSessionProvider).valueOrNull;
      if (session == null) return null;
      return ref
          .watch(dashboardRepositoryProvider)
          .loadProjectSnapshot(session.database, session.manifest.id);
    });
```
---
**BUG-03** | Severity: Medium | Points: 5
- **File:** lib/features/dashboard/presentation/dashboard_screen.dart
- **Line(s):** 24-26
- **Category:** logic
- **Claim:** Attempting to create a character when no project session exists navigates to the generic studio route without a project ID parameter.
- **Evidence:**
```dart
    final session = ref.read(projectSessionProvider).valueOrNull;
    if (session == null) {
      if (context.mounted) context.go(AppRoutes.studio);
      return;
    }
```
---
**BUG-04** | Severity: Low | Points: 1
- **File:** lib/features/dashboard/presentation/widgets/recent_assets.dart
- **Line(s):** 28-38
- **Category:** data-integrity
- **Claim:** The recent assets widget displays hardcoded mock asset items instead of reflecting real project assets from the snapshot provider.
- **Evidence:**
```dart
                children: const [
                  _AssetTile(icon: Icons.person_outline, label: 'Qowner'),
                  _AssetTile(
                    icon: Icons.checkroom_outlined,
                    label: 'Void Coat',
                  ),
                  _AssetTile(
                    icon: Icons.auto_fix_high_outlined,
                    label: 'Dual Dagger',
                  ),
                ],
```
---
**BUG-05** | Severity: Low | Points: 1
- **File:** lib/features/dashboard/presentation/widgets/donation_card.dart
- **Line(s):** 40-56
- **Category:** logic
- **Claim:** Donation payment buttons invoke a stub feedback handler showing an unconfigured integration message rather than handling actual payment processing.
- **Evidence:**
```dart
              OutlinedButton(
                onPressed: () => _feedback(context),
                child: const Text('QRIS'),
              ),
```
---
**BUG-06** | Severity: Low | Points: 1
- **File:** lib/features/dashboard/presentation/widgets/recent_projects.dart
- **Line(s):** 44-46
- **Category:** performance
- **Claim:** Sorting and slicing the recent projects list occurs directly inside the build method on every widget rebuild without memoization.
- **Evidence:**
```dart
          final recent = [...items]
            ..sort((a, b) => b.lastOpenedAt.compareTo(a.lastOpenedAt));
          final visible = recent.take(4).toList();
```
---
**BUG-07** | Severity: Low | Points: 1
- **File:** lib/features/dashboard/presentation/widgets/statistics_panel.dart
- **Line(s):** 32-35
- **Category:** error-handling
- **Claim:** The statistics panel error state renders a static error message without providing a retry or recovery mechanism.
- **Evidence:**
```dart
            error: (error, stack) => const Text(
              'Project statistics are unavailable.',
              style: VoidTypography.body,
            ),
```
---
**BUG-08** | Severity: Low | Points: 1
- **File:** lib/features/dashboard/presentation/dashboard_screen.dart
- **Line(s):** 74
- **Category:** error-handling
- **Claim:** The authentication session loading error state displays raw unformatted error text directly to the user interface.
- **Evidence:**
```dart
          error: (error, stack) => Center(child: Text('$error')),
```
---
**BUG-09** | Severity: Low | Points: 1
- **File:** lib/features/dashboard/presentation/widgets/recent_projects.dart
- **Line(s):** 151-153
- **Category:** edge-case
- **Claim:** Thumbnail file path resolution relies on direct path joining which may fail if relative thumbnail paths are malformed or invalid relative to project local paths.
- **Evidence:**
```dart
                File(
                  path.isAbsolute(thumbnail)
                      ? thumbnail
                      : path.join(project.localPath, thumbnail),
                ),
```
---

**TOTAL FINDINGS:** 9
**TOTAL SCORE:** 21
