import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';
import 'package:void_scriptor/app/routing/app_router.dart';
import 'package:void_scriptor/app/routing/app_routes.dart';
import 'package:void_scriptor/core/build_identity.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';
import 'package:void_scriptor/features/settings/presentation/settings_hub_screen.dart';

class NullSessionController extends ProjectSessionController {
  @override
  Future<ProjectSession?> build() async => null;
}

void main() {
  Widget wrap(Widget child) => ProviderScope(
    overrides: [
      projectSessionProvider.overrideWith(() => NullSessionController()),
    ],
    child: MaterialApp(home: child),
  );

  testWidgets('Settings Hub menampilkan empat section destination', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const SettingsHubScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsWidgets);
    expect(find.text('General'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Sidebar & Workspace'), findsOneWidget);
    expect(find.text('About & Diagnostics'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Appearance membuka ThemeSettings dengan kontrol theme nyata', (
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
    await tester.tap(find.text('Appearance'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Theme'));
    await tester.pumpAndSettle();
    expect(find.text('Dark'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('System'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('About & Diagnostics menampilkan versi aplikasi nyata', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const SettingsHubScreen()));
    await tester.pumpAndSettle();
    expect(find.text(BuildIdentity.version), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tidak overflow di lebar sempit 390px', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(wrap(const SettingsHubScreen()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Sidebar & Workspace jujur saat belum ada proyek terbuka', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const SettingsHubScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sidebar & Workspace'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Buka proyek'),
      findsWidgets,
      reason:
          'Tanpa sesi proyek, section sidebar harus memberi arah, bukan kontrol mati.',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Storage Locations terjangkau dari Hub dan membuka status nyata',
    (tester) async {
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
      // 'About & Diagnostics' ber-ExpansionTile initiallyExpanded — tanpa tap.
      final dest = find.text('Lokasi penyimpanan kustom');
      await tester.ensureVisible(dest);
      await tester.pumpAndSettle();
      await tester.tap(dest);
      await tester.pumpAndSettle();
      expect(find.text('Storage Locations'), findsOneWidget);
      expect(
        find.text('Lokasi penyimpanan kustom'),
        findsWidgets,
        reason: 'Layar storage harus menampilkan kartu status nyata.',
      );
      expect(tester.takeException(), isNull);
    },
  );
}
