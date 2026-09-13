// vs-hunt-20260913-dashboard BUG-03 (Referee REAL BUG, Medium):
// Dashboard quick action "Create Character" tanpa sesi proyek aktif menavigasi
// ke AppRoutes.studio (/studio) yang me-render VoidAppShell tanpa projectId —
// shell tanpa sesi: karakter tidak mungkin dibuat dan pengguna terlantar di
// workspace kosong. Kontrak shell yang sudah berdiri (onMenuSelected
// session==null => context.go(AppRoutes.projects)): destinasi tanpa sesi harus
// mendarat di daftar Proyek, bukan shell mati.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:void_scriptor/app/routing/app_routes.dart';
import 'package:void_scriptor/core/auth/auth_controller.dart';
import 'package:void_scriptor/core/auth/auth_session.dart';
import 'package:void_scriptor/features/dashboard/presentation/dashboard_screen.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';

class _GuestAuthController extends AuthController {
  @override
  Future<AuthSession> build() async => const AuthSession.guest();
}

class _NullSessionController extends ProjectSessionController {
  @override
  Future<ProjectSession?> build() async => null;
}

void main() {
  testWidgets(
    'Create Character tanpa sesi aktif mengarahkan pengguna ke daftar Proyek',
    (tester) async {
      tester.view
        ..physicalSize = const Size(1440, 1200)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final placeholderRoutes = {
        AppRoutes.projects: 'Projects Page',
        AppRoutes.studio: 'Studio Page',
        AppRoutes.workspace: 'Workspace Page',
      };
      final router = GoRouter(
        initialLocation: AppRoutes.dashboard,
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            builder: (context, state) => const DashboardScreen(),
          ),
          for (final entry in placeholderRoutes.entries)
            GoRoute(
              path: entry.key,
              builder: (context, state) =>
                  Scaffold(body: Center(child: Text(entry.value))),
            ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(_GuestAuthController.new),
            projectSessionProvider.overrideWith(_NullSessionController.new),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('Dashboard'), findsOneWidget);

      await tester.tap(find.text('Create Character'));
      await tester.pumpAndSettle();

      // BUG-03: di HEAD lama ini mendarat di '/studio' (shell tanpa sesi).
      // Kontrak benar: daftar Proyek sebagai jalur pemulihan nyata.
      expect(
        router.routerDelegate.currentConfiguration.matches.last.matchedLocation,
        AppRoutes.projects,
      );
      expect(find.text('Studio Page'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
