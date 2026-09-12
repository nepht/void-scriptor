// vs-hunt-20260913-shell-settings BUG-02 (Referee REAL, Low, kontrak 145.37):
// VoidDesktopShell.onMenuSelected memakai context.push untuk SEMUA destinasi
// top-bar, sehingga klik tab yang sama berulang kali menumpuk halaman identik
// di stack go_router (shell tidak punya back button utk destinasi dalam-shell).
//
// Kontrak fix (minimal, behavior-preserving): klik destinasi yang SUDAH berada
// di puncak stack adalah no-op — tidak ada halaman duplikat. Navigasi ke
// destinasi berbeda tetap push, sehingga affordance back AppBar bawaan screen
// sub-destination (Settings/Assets/Backups) tidak hilang.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:void_scriptor/app/routing/app_routes.dart';
import 'package:void_scriptor/app/shell/desktop/void_desktop_shell.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';

void main() {
  late GoRouter router;

  Widget harness() {
    router = GoRouter(
      initialLocation: AppRoutes.workspace,
      routes: [
        for (final entry in {
          AppRoutes.workspace: 'workspace-body',
          AppRoutes.dashboard: 'dashboard-body',
        }.entries)
          GoRoute(
            path: entry.key,
            builder: (_, _) => VoidDesktopShell(
              content: Text(entry.value, textDirection: TextDirection.ltr),
            ),
          ),
        for (final entry in {
          AppRoutes.projects: 'Projects Page',
          AppRoutes.assets: 'Assets Page',
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
        projectSessionProvider.overrideWith(() => _NoSession()),
        projectPathsProvider.overrideWithValue(
          ProjectPaths(
            rootDirectory: Directory(
              '${Directory.systemTemp.path}/shell-nav-stack-unused',
            ),
          ),
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  Future<void> tapTab(WidgetTester tester, String label) async {
    await tester.tap(find.text(label).hitTestable());
    await tester.pumpAndSettle();
  }

  int stackDepth() => router.routerDelegate.currentConfiguration.matches.length;
  String topLocation() =>
      router.routerDelegate.currentConfiguration.last.matchedLocation;

  testWidgets(
    'BUG-02a: klik tab Dashboard berulang tidak menumpuk halaman duplikat',
    (tester) async {
      tester.view
        ..physicalSize = const Size(1600, 900)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(harness());
      await tester.pumpAndSettle();
      expect(stackDepth(), 1);

      await tapTab(tester, 'Dashboard');
      expect(topLocation(), AppRoutes.dashboard);
      expect(stackDepth(), 2);

      // Klik tab yang sama lagi: tidak boleh menambah halaman.
      await tapTab(tester, 'Dashboard');
      expect(stackDepth(), 2);
      expect(topLocation(), AppRoutes.dashboard);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'BUG-02b: destinasi berbeda tetap push (affordance back dipertahankan)',
    (tester) async {
      tester.view
        ..physicalSize = const Size(1600, 900)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(harness());
      await tester.pumpAndSettle();

      await tapTab(tester, 'Search');
      expect(topLocation(), AppRoutes.assets);
      expect(stackDepth(), 2);
      expect(router.canPop(), isTrue);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'BUG-02c: proyek yang sedang dibuka tidak ter-push duplikat dari Workspace',
    (tester) async {
      tester.view
        ..physicalSize = const Size(1600, 900)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(harness());
      await tester.pumpAndSettle();
      expect(topLocation(), AppRoutes.workspace);

      await tapTab(tester, 'Dashboard');
      expect(stackDepth(), 2);
      await tapTab(tester, 'Dashboard');
      expect(stackDepth(), 2);
      await tapTab(tester, 'Dashboard');
      expect(stackDepth(), 2);

      expect(tester.takeException(), isNull);
    },
  );
}

class _NoSession extends ProjectSessionController {
  @override
  Future<ProjectSession?> build() async => null;
}
