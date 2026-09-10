import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:void_scriptor/app/routing/app_routes.dart';
import 'package:void_scriptor/app/shell/mobile/void_mobile_shell.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';

/// hunt-run171 BUG-7 (Referee REAL BUG, Medium):
///
/// `VoidMobileShell._goToDestination` gates `requiresProject` destinations on
/// `widget.projectId`, which is non-null only on `/studio/:projectId`. The
/// normal navigation path rewrites Characters/World to `AppRoutes.workspace`
/// (no projectId), so on `/workspace` with a LIVE open session the Characters
/// destination wrongly pushes the Projects list instead of the workspace, and
/// the `focusExplorerAsset` typed-focus calls are never reached.
///
/// Fix contract (Referee): gate on the live Riverpod session
/// (`currentProjectIdProvider`) instead of the constructor param; the
/// param-based behavior is preserved when no session exists (Projects page).
void main() {
  /// Real temp project + real Drift session (proven harness pattern: all real
  /// I/O inside tester.runAsync).
  Future<ProjectSession?> seedSession(WidgetTester tester) async {
    late Directory root;
    late ProjectSession session;
    await tester.runAsync(() async {
      root = await Directory.systemTemp.createTemp('hunt171b7-');
      final package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'Hunt 171 B7');
      session = await ProjectSessionManager().open(package);
    });
    addTearDown(() async {
      await session.close();
      if (root.existsSync()) root.deleteSync(recursive: true);
    });
    return session;
  }

  Widget harness({
    required String initialLocation,
    required ProjectSession? session,
  }) {
    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: '/studio/:projectId',
          builder: (_, _) => const VoidMobileShell(),
        ),
        GoRoute(
          path: AppRoutes.workspace,
          builder: (_, _) => const VoidMobileShell(),
        ),
        for (final entry in {
          AppRoutes.projects: 'Projects Page',
          AppRoutes.assets: 'Assets Page',
          AppRoutes.dashboard: 'Dashboard Page',
        }.entries)
          GoRoute(
            path: entry.key,
            builder: (_, _) => Scaffold(body: Text(entry.value)),
          ),
      ],
    );
    addTearDown(router.dispose);
    return ProviderScope(
      overrides: [
        projectSessionProvider.overrideWith(() => _FixedSession(session)),
        projectPathsProvider.overrideWithValue(
          ProjectPaths(
            rootDirectory: Directory(
              '${Directory.systemTemp.path}/hunt171b7-paths',
            ),
          ),
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  Future<void> tapCharacters(WidgetTester tester) async {
    await tester.tap(find.text('Characters').first);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'BUG-7a: /workspace with a LIVE session must NOT bounce Characters to Projects',
    (tester) async {
      final session = await seedSession(tester);
      await tester.pumpWidget(
        harness(initialLocation: AppRoutes.workspace, session: session),
      );
      await tester.pumpAndSettle();

      await tapCharacters(tester);

      expect(
        find.text('Projects Page'),
        findsNothing,
        reason:
            'BUG-7: with an open session, Characters must not push Projects',
      );
      // The guard consumed the tap as a workspace navigation: the shell route
      // is still the active surface (pushed '/workspace' on top of it).
      expect(find.byType(VoidMobileShell), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'BUG-7b: requiresProject guard with NO session still routes to Projects',
    (tester) async {
      await tester.pumpWidget(
        harness(initialLocation: AppRoutes.workspace, session: null),
      );
      await tester.pumpAndSettle();

      await tapCharacters(tester);
      await tester.pumpAndSettle();
      expect(find.text('Projects Page'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

class _FixedSession extends ProjectSessionController {
  _FixedSession(this._session);

  final ProjectSession? _session;

  @override
  Future<ProjectSession?> build() async => _session;
}
