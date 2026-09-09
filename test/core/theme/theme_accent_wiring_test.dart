// Wiring accent: VoidScriptorApp memakai VoidThemeVariant sesuai aksen
// terpilih, dan ThemeSettingsScreen menyediakan pemilih warna.
//
// Choi: "terapkan model berbagai warna tema agar memiliki banyak pilihan
// warna" — pilihan harus benar-benar mengubah tampilan aplikasi.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:void_scriptor/app/void_app.dart';
import 'package:void_scriptor/core/theme/app_theme_mode.dart';
import 'package:void_scriptor/core/theme/theme_preference_store.dart';
import 'package:void_scriptor/design_system/theme/void_palette.dart';
import 'package:void_scriptor/design_system/theme/void_theme_variant.dart';
import 'package:void_scriptor/features/platform/presentation/theme_settings_screen.dart';

void main() {
  testWidgets('VoidScriptorApp memakai palet aksen terpilih (ocean, light)', (
    tester,
  ) async {
    final store = InMemoryThemePreferenceStore();
    await store.save(AppThemeMode.light);
    await store.saveAccent(VoidThemeAccent.ocean);

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('home')),
        ),
      ],
    );
    addTearDown(router.dispose);

    final container = ProviderContainer(
      overrides: [themePreferenceStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: VoidScriptorApp(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(Scaffold).first);
    expect(
      Theme.of(context).colorScheme.primary,
      VoidThemeVariant.ocean.lightPalette.primary,
      reason: 'accent ocean harus mengganti warna primer aplikasi',
    );
    expect(
      Theme.of(context).extension<VoidPalette>()?.background,
      VoidThemeVariant.ocean.lightPalette.background,
      reason: 'seluruh palette harus mengikuti preset ocean',
    );
  });

  testWidgets(
    'ThemeSettingsScreen menampilkan 6 pilihan warna & bisa dipilih',
    (tester) async {
      final store = InMemoryThemePreferenceStore();
      final container = ProviderContainer(
        overrides: [themePreferenceStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ThemeSettingsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Void Purple'), findsOneWidget);
      expect(find.text('Ink'), findsOneWidget);
      expect(find.text('Ember'), findsOneWidget);
      expect(find.text('Sage'), findsOneWidget);
      expect(find.text('Rose'), findsOneWidget);
      expect(find.text('Ocean'), findsOneWidget);

      await tester.tap(find.text('Rose'));
      await tester.pumpAndSettle();
      expect(await store.loadAccent(), VoidThemeAccent.rose);
    },
  );
}
