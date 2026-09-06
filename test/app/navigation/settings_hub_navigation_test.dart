import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/app/routing/app_router.dart';
import 'package:void_scriptor/app/routing/app_routes.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';

class NullSessionController extends ProjectSessionController {
  @override
  Future<ProjectSession?> build() async => null;
}

void main() {
  testWidgets('route /settings membuka Settings Hub, bukan screen theme saja', (
    tester,
  ) async {
    final router = createAppRouter(initialLocation: AppRoutes.settings);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          projectSessionProvider.overrideWith(() => NullSessionController()),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('General'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Sidebar & Workspace'), findsOneWidget);
    expect(find.text('About & Diagnostics'), findsOneWidget);
  });

  testWidgets(
    'destination Settings di top bar desktop terhubung ke Settings Hub',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1600, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final router = createAppRouter(initialLocation: AppRoutes.workspace);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            projectSessionProvider.overrideWith(() => NullSessionController()),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('General'),
        findsNothing,
        reason: 'Belum di Settings Hub.',
      );
      final settingsItem = find.text('Settings');
      expect(settingsItem, findsWidgets);
      await tester.ensureVisible(settingsItem.first);
      await tester.tap(settingsItem.first);
      await tester.pumpAndSettle();
      expect(
        find.text('General'),
        findsOneWidget,
        reason: 'Top bar Settings harus membuka Settings Hub.',
      );
      expect(tester.takeException(), isNull);
    },
  );
}
