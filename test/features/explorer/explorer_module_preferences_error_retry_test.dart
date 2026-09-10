import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/features/explorer/application/project_sidebar_module_preferences.dart';
import 'package:void_scriptor/features/explorer/presentation/explorer_panel.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';

/// Regression for hunt-20260910 run171 BUG-20 (Referee REAL BUG Low).
///
/// When `projectSidebarModulePreferencesProvider` enters `AsyncError`
/// (disk/DB failure in `load()`), the old code silently fell back to
/// `valueOrNull ?? const defaults` with no error surface and no retry —
/// the user kept default sidebar modules with no indication anything
/// failed, in contrast to the error + retry rows used for catalog groups
/// (BUG-8 pattern in the same file).
///
/// Contract:
/// - A module-preferences load failure surfaces an inline error row naming
///   the failure and offering a retry that re-runs the load.
/// - A healthy load never renders the error row and still drives module
///   visibility (positive control).
void main() {
  Finder moduleErrorRow() => find.textContaining('Sidebar modules unavailable');

  testWidgets(
    'module preferences load failure shows error row with retry that recovers',
    (tester) async {
      final session = await tester.runAsync(() async {
        final root = await Directory.systemTemp.createTemp(
          'module-prefs-error-',
        );
        final package = await ProjectPackageService(
          rootDirectory: root,
        ).create(name: 'Module prefs error project');
        return ProjectSessionManager().open(package);
      });
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        await tester.runAsync(() async {
          await session?.close();
        });
      });
      expect(session, isNotNull);

      final service = _FailingThenGoodModulePreferencesService();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            projectSessionProvider.overrideWith(() => _FixedSession(session!)),
            projectSidebarModulePreferencesServiceProvider.overrideWithValue(
              service,
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: ExplorerPanel())),
        ),
      );
      // First pump resolves the session; second lets the family provider
      // reach the (failing) service.
      await tester.pump();
      await tester.pump();

      // RED (pre-patch): AsyncError silently fell back to defaults — no
      // error row and no retry anywhere in the panel.
      expect(moduleErrorRow(), findsOneWidget);

      // Retry invalidates the provider; this attempt succeeds.
      service.failNextLoad = false;
      await tester.tap(find.byTooltip('Retry sidebar modules'));
      await tester.pump();
      await tester.pump();

      expect(moduleErrorRow(), findsNothing);
      expect(service.loadCalls, 2);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'healthy module preferences render without error row (positive control)',
    (tester) async {
      final session = await tester.runAsync(() async {
        final root = await Directory.systemTemp.createTemp(
          'module-prefs-good-',
        );
        final package = await ProjectPackageService(
          rootDirectory: root,
        ).create(name: 'Module prefs good project');
        return ProjectSessionManager().open(package);
      });
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        await tester.runAsync(() async {
          await session?.close();
        });
      });
      expect(session, isNotNull);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            projectSessionProvider.overrideWith(() => _FixedSession(session!)),
            projectSidebarModulePreferencesServiceProvider.overrideWithValue(
              _GoodModulePreferencesService(),
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: ExplorerPanel())),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(moduleErrorRow(), findsNothing);
      // The healthy preference keeps creatures visible.
      expect(find.text('Creatures & Companions'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

class _ModulePreferencesLoadException implements Exception {
  const _ModulePreferencesLoadException();
  @override
  String toString() => 'module preferences disk io failed';
}

class _FailingThenGoodModulePreferencesService
    extends ProjectSidebarModulePreferencesService {
  bool failNextLoad = true;
  int loadCalls = 0;

  @override
  Future<ProjectSidebarModulePreferences> load({
    required package,
    required database,
    required String projectId,
  }) async {
    loadCalls++;
    if (failNextLoad) {
      throw const _ModulePreferencesLoadException();
    }
    return const ProjectSidebarModulePreferences(
      factions: false,
      relationshipMap: true,
    );
  }
}

class _GoodModulePreferencesService
    extends ProjectSidebarModulePreferencesService {
  @override
  Future<ProjectSidebarModulePreferences> load({
    required package,
    required database,
    required String projectId,
  }) async => const ProjectSidebarModulePreferences(
    factions: false,
    relationshipMap: true,
  );
}

class _FixedSession extends ProjectSessionController {
  _FixedSession(this.session);
  final ProjectSession session;
  @override
  Future<ProjectSession?> build() async => session;
}
