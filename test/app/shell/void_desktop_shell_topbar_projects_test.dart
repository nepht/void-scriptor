// hunt-run171 BUG-4 (Referee REAL BUG, Medium):
//
// VoidDesktopShell.onMenuSelected memanggil explorerAssetTypeForMenu(menu)
// SEBELUM switch route. Karena explorer_panel.dart memetakan
// 'story' || 'novels' => AssetType.story, menu 'novels' (tombol top-bar
// desktop berlabel "Projects", destinasi global AppRoutes.projects) selalu
// terintersep menjadi focusExplorerAsset(AssetType.story) + push /workspace.
// Dengan sesi live, tombol "Projects" tidak pernah membuka daftar proyek dan
// arm 'novels' => AppRoutes.projects adalah dead code (bukti intent: key
// 'novels' lahir dari AppNavigationDestination dengan route projects).
//
// Kontrak fix (Referee): 'novels' adalah destinasi global Projects, bukan
// fokus aset Explorer. Tanpa sesi tetap ke daftar proyek (perilaku lama).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:void_scriptor/app/routing/app_routes.dart';
import 'package:void_scriptor/app/shell/desktop/void_desktop_shell.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';

void main() {
  Future<ProjectSession> seedSession(WidgetTester tester) async {
    late Directory root;
    late ProjectSession session;
    await tester.runAsync(() async {
      root = await Directory.systemTemp.createTemp('hunt171b4-');
      final package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'Hunt 171 B4');
      session = await ProjectSessionManager().open(package);
    });
    addTearDown(() async {
      await session.close();
      if (root.existsSync()) root.deleteSync(recursive: true);
    });
    return session;
  }

  Widget harness({required ProjectSession? session}) {
    final router = GoRouter(
      initialLocation: AppRoutes.workspace,
      routes: [
        GoRoute(
          path: AppRoutes.workspace,
          builder: (_, _) =>
              const VoidDesktopShell(content: Text('workspace-body')),
        ),
        for (final entry in {
          AppRoutes.projects: 'Projects Page',
          AppRoutes.dashboard: 'Dashboard Page',
        }.entries)
          GoRoute(
            path: entry.key,
            builder: (_, _) => Scaffold(body: Center(child: Text(entry.value))),
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
              '${Directory.systemTemp.path}/hunt171b4-paths',
            ),
          ),
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  Future<void> tapProjects(WidgetTester tester) async {
    await tester.tap(find.text('Projects').first);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'BUG-4a: top-bar Projects dengan sesi live membuka daftar proyek, bukan Novel workspace',
    (tester) async {
      tester.view
        ..physicalSize = const Size(1600, 900)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final session = await seedSession(tester);
      await tester.pumpWidget(harness(session: session));
      await tester.pumpAndSettle();

      await tapProjects(tester);

      expect(find.text('Projects Page'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'BUG-4b: tanpa sesi tetap ke daftar proyek (kontrak lama terkunci)',
    (tester) async {
      tester.view
        ..physicalSize = const Size(1600, 900)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(harness(session: null));
      await tester.pumpAndSettle();

      await tapProjects(tester);

      expect(find.text('Projects Page'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

class _FixedSession extends ProjectSessionController {
  _FixedSession(this.session);
  final ProjectSession? session;
  @override
  Future<ProjectSession?> build() async => session;
}
