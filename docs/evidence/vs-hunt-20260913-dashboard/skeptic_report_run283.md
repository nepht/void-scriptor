---
**BUG-01** | Original: 5 pts
- **Counter-argument:** The repository fetches all records via `getAllAssets()` and filters them in memory rather than utilizing a DAO query filtered by project ID. While inefficient for large databases, this is a real data-access performance flaw in the snapshot loader.
- **Evidence:**
```dart
    final assetsFuture = database.assetDao.getAllAssets();
    ...
    final assets = await assetsFuture;
    ...
      assets: assets.where((asset) => asset.projectId == projectId).length,
```
- **Confidence:** 95%
- **Risk calc:** EV = (95% x 5) - (5% x 10) = 4.75 - 0.50 = +4.25
- **Decision:** ACCEPT
---

**BUG-02** | Original: 5 pts
- **Counter-argument:** Riverpod's `FutureProvider` automatically catches exceptions thrown in its async body and exposes them as `AsyncValue.error` to consumers, which are explicitly handled in `StatisticsPanel`. An explicit try/catch block inside the provider callback is redundant.
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
- **Confidence:** 90%
- **Risk calc:** EV = (90% x 5) - (10% x 10) = 4.50 - 1.00 = +3.50
- **Decision:** DISPROVE
---

**BUG-03** | Original: 5 pts
- **Counter-argument:** When no project session exists, clicking create character navigates directly to `AppRoutes.studio` without passing a project ID parameter, stranding the user without project context.
- **Evidence:**
```dart
    final session = ref.read(projectSessionProvider).valueOrNull;
    if (session == null) {
      if (context.mounted) context.go(AppRoutes.studio);
      return;
    }
```
- **Confidence:** 95%
- **Risk calc:** EV = (95% x 5) - (5% x 10) = 4.75 - 0.50 = +4.25
- **Decision:** ACCEPT
---

**BUG-04** | Original: 1 pts
- **Counter-argument:** The `RecentAssets` widget renders hardcoded static mock tiles ('Qowner', 'Void Coat', 'Dual Dagger') instead of reflecting dynamic project assets from the database snapshot.
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
- **Confidence:** 95%
- **Risk calc:** EV = (95% x 1) - (5% x 2) = 0.95 - 0.10 = +0.85
- **Decision:** ACCEPT
---

**BUG-05** | Original: 1 pts
- **Counter-argument:** As explicitly specified in the project domain notes, deferred payment integration is out of core scope for this local-first desktop IDE. Providing a stub handler that shows honest feedback ('Donation integration is not configured yet.') is correct and by-design rather than faking payment processing.
- **Evidence:**
```dart
              OutlinedButton(
                onPressed: () => _feedback(context),
                child: const Text('QRIS'),
              ),
```
- **Confidence:** 95%
- **Risk calc:** EV = (95% x 1) - (5% x 2) = 0.95 - 0.10 = +0.85
- **Decision:** DISPROVE
---

**BUG-06** | Original: 1 pts
- **Counter-argument:** Sorting and slicing a small in-memory list of recent projects (typically a handful of items) inside the build method has negligible performance cost in Flutter and does not warrant memoization overhead.
- **Evidence:**
```dart
          final recent = [...items]
            ..sort((a, b) => b.lastOpenedAt.compareTo(a.lastOpenedAt));
          final visible = recent.take(4).toList();
```
- **Confidence:** 90%
- **Risk calc:** EV = (90% x 1) - (10% x 2) = 0.90 - 0.20 = +0.70
- **Decision:** DISPROVE
---

**BUG-07** | Original: 1 pts
- **Counter-argument:** The statistics panel error state renders static text without providing any user recovery or retry mechanism, unlike other widgets (e.g., RecentProjects) which offer a retry button.
- **Evidence:**
```dart
            error: (error, stack) => const Text(
              'Project statistics are unavailable.',
              style: VoidTypography.body,
            ),
```
- **Confidence:** 90%
- **Risk calc:** EV = (90% x 1) - (10% x 2) = 0.90 - 0.20 = +0.70
- **Decision:** ACCEPT
---

**BUG-08** | Original: 1 pts
- **Counter-argument:** The authentication session loading error state directly interpolates and displays raw exception strings (`$error`) in the UI without formatting or user-friendly messaging.
- **Evidence:**
```dart
          error: (error, stack) => Center(child: Text('$error')),
```
- **Confidence:** 95%
- **Risk calc:** EV = (95% x 1) - (5% x 2) = 0.95 - 0.10 = +0.85
- **Decision:** ACCEPT
---

**BUG-09** | Original: 1 pts
- **Counter-argument:** Potential thumbnail path resolution or file loading errors are explicitly caught and handled by `errorBuilder: (_, _, _) => placeholder`, preventing crashes and rendering the fallback safely.
- **Evidence:**
```dart
                File(
                  path.isAbsolute(thumbnail)
                      ? thumbnail
                      : path.join(project.localPath, thumbnail),
                ),
```
- **Confidence:** 95%
- **Risk calc:** EV = (95% x 1) - (5% x 2) = 0.95 - 0.10 = +0.85
- **Decision:** DISPROVE
---

**SUMMARY:**
- Bugs disproved: 4 (total points claimed: 8)
- Bugs accepted as real: 5
- Your final score: 8

**ACCEPTED BUG LIST:**
- BUG-01
- BUG-03
- BUG-04
- BUG-07
- BUG-08
