# Adversarial Bug Hunt: Referee Report (Run 283)

- **Repository:** D:\VoidScriptor\void_scriptor_multiplatform
- **Branch:** master
- **HEAD Commit:** 4027dcd2fe2a05f920cb42308d3717d7f07be145
- **Scan Date:** 2026-09-13
- **Region:** Dashboard (`lib/features/dashboard/**`)

---

## Evaluation of Findings

---
**BUG-01**
- **Hunter's claim:** The repository fetches all assets across the entire database and filters them in memory rather than querying the database directly by project identifier.
- **Skeptic's response:** ACCEPT.
- **Your analysis:** Independent inspection of `lib/features/dashboard/data/dashboard_repository.dart` confirms that `database.assetDao.getAllAssets()` loads all records into memory, followed by `assets.where((asset) => asset.projectId == projectId).length`. While functional for small databases, this is an inefficient data access pattern that bypasses project-scoped DAO filtering.
- **VERDICT:** REAL BUG
- **Confidence:** High
- **True severity:** Medium
- **Suggested fix:** Add a project-scoped query method on `AssetDao` (e.g. `getAssetsForProject(projectId)`) or filter directly in the database query.
---

---
**BUG-02**
- **Hunter's claim:** The dashboard snapshot future provider lacks explicit error handling or try-catch block when underlying DAO database queries fail.
- **Skeptic's response:** DISPROVE. Riverpod's `FutureProvider` automatically intercepts exceptions in its asynchronous callback and exposes them as `AsyncValue.error` to consumers. Explicit try/catch inside a provider callback is redundant.
- **Your analysis:** Examined `lib/features/dashboard/application/dashboard_snapshot_provider.dart`. Riverpod natively wraps async providers, propagating errors cleanly. The Skeptic is correct; this is standard Riverpod usage, not a bug.
- **VERDICT:** NOT A BUG
- **Confidence:** High
---

---
**BUG-03**
- **Hunter's claim:** Attempting to create a character when no project session exists navigates to the generic studio route without a project ID parameter.
- **Skeptic's response:** ACCEPT.
- **Your analysis:** Examined `lib/features/dashboard/presentation/dashboard_screen.dart` (`_createCharacter`). When `session == null`, it calls `context.go(AppRoutes.studio)`. Since `AppRoutes.studio` expects a project ID parameter (e.g. `/studio/:projectId`), navigating without one results in a routing parameter mismatch or stranded UI state.
- **VERDICT:** REAL BUG
- **Confidence:** High
- **True severity:** Medium
- **Suggested fix:** Guard the action to check for a valid project session, prompt the user to open/create a project first, or disable the quick action button when no active project session exists.
---

---
**BUG-04**
- **Hunter's claim:** The recent assets widget displays hardcoded mock asset items instead of reflecting real project assets from the snapshot provider.
- **Skeptic's response:** ACCEPT.
- **Your analysis:** Examined `lib/features/dashboard/presentation/widgets/recent_assets.dart`. The widget renders hardcoded static tiles ('Qowner', 'Void Coat', 'Dual Dagger') regardless of project database state or actual assets. This is hardcoded fake data in a production dashboard component.
- **VERDICT:** REAL BUG
- **Confidence:** High
- **True severity:** Low
- **Suggested fix:** Wire `RecentAssets` to a dynamic project asset provider or hide/stub the widget cleanly until asset tracking is implemented.
---

---
**BUG-05**
- **Hunter's claim:** Donation payment buttons invoke a stub feedback handler showing an unconfigured integration message rather than handling actual payment processing.
- **Skeptic's response:** DISPROVE. Deferred payment integration is out of core scope for this local-first desktop IDE. Providing a stub handler showing an honest feedback message is by-design.
- **Your analysis:** Examined `lib/features/dashboard/presentation/widgets/donation_card.dart`. The buttons show a Snackbar stating 'Donation integration is not configured yet.' This is an honest stub, not a bug.
- **VERDICT:** NOT A BUG
- **Confidence:** High
---

---
**BUG-06**
- **Hunter's claim:** Sorting and slicing the recent projects list occurs directly inside the build method on every widget rebuild without memoization.
- **Skeptic's response:** DISPROVE. Sorting a small in-memory list of recent projects in the build method has negligible performance cost.
- **Your analysis:** Examined `lib/features/dashboard/presentation/widgets/recent_projects.dart`. Sorting a list of a handful of recent projects in memory inside a build method is standard Flutter practice and causes no perceptible jank.
- **VERDICT:** NOT A BUG
- **Confidence:** High
---

---
**BUG-07**
- **Hunter's claim:** The statistics panel error state renders a static error message without providing a retry or recovery mechanism.
- **Skeptic's response:** ACCEPT.
- **Your analysis:** Examined `lib/features/dashboard/presentation/widgets/statistics_panel.dart`. The error state renders a static text message without any user retry mechanism or error recovery action (unlike `RecentProjects`, which offers a retry button).
- **VERDICT:** REAL BUG
- **Confidence:** High
- **True severity:** Low
- **Suggested fix:** Add a retry action or `ref.invalidate(dashboardSnapshotProvider)` button in the statistics panel error handler.
---

---
**BUG-08**
- **Hunter's claim:** The authentication session loading error state displays raw unformatted error text directly to the user interface.
- **Skeptic's response:** ACCEPT.
- **Your analysis:** Examined `lib/features/dashboard/presentation/dashboard_screen.dart`. The error builder returns `Center(child: Text('$error'))`, interpolating raw exception strings directly into the UI.
- **VERDICT:** REAL BUG
- **Confidence:** High
- **True severity:** Low
- **Suggested fix:** Wrap authentication error states in a user-friendly error container with clear messaging and recovery options.
---

---
**BUG-09**
- **Hunter's claim:** Thumbnail file path resolution relies on direct path joining which may fail if relative thumbnail paths are malformed or invalid relative to project local paths.
- **Skeptic's response:** DISPROVE. `errorBuilder: (_, _, _) => placeholder` handles missing or malformed thumbnail files gracefully without crashing.
- **Your analysis:** Examined `lib/features/dashboard/presentation/widgets/recent_projects.dart`. `Image.file` is wrapped with an explicit `errorBuilder` that falls back to `placeholder`, safely preventing runtime exceptions.
- **VERDICT:** NOT A BUG
- **Confidence:** High
---

## VERIFIED BUG REPORT

**Stats:**
- Total reported by Hunter: 9
- Dismissed as false positives: 4
- Confirmed as real bugs: 5
- Critical: 0 | Medium: 2 | Low: 3

**Confirmed bugs (ordered by severity):**

| # | Severity | File | Line(s) | Description | Suggested Fix |
|---|----------|------|---------|-------------|---------------|
| BUG-01 | Medium | lib/features/dashboard/data/dashboard_repository.dart | 11, 31 | Fetches all assets in DB and filters in memory | Add project-scoped DAO query |
| BUG-03 | Medium | lib/features/dashboard/presentation/dashboard_screen.dart | 24-26 | Navigates to studio route without projectId when session is null | Guard navigation or prompt user to create/open project first |
| BUG-04 | Low | lib/features/dashboard/presentation/widgets/recent_assets.dart | 28-38 | Displays hardcoded static mock asset tiles | Wire to asset provider or remove stub |
| BUG-07 | Low | lib/features/dashboard/presentation/widgets/statistics_panel.dart | 32-35 | Statistics error state lacks retry mechanism | Add retry action/invalidation |
| BUG-08 | Low | lib/features/dashboard/presentation/dashboard_screen.dart | 74 | Displays raw unformatted auth error text | Provide user-friendly error UI |

**Low-confidence items (flagged for manual review):**
None (all evaluated with High confidence).
