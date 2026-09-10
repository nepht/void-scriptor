// Akses cepat aksen dari ThemeModeMenu top-bar (polish run184):
// penulis mengganti warna tanpa membuka halaman Settings penuh.
// Kontrak: submenu "Accent color" berisi 6 warna; memilih salah satu
// memanggil ThemeAccentController.setAccent (persisten) dan mode
// lama (System/Light/Dark) tetap berfungsi.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/theme/app_theme_mode.dart';
import 'package:void_scriptor/core/theme/theme_controller.dart';
import 'package:void_scriptor/core/theme/theme_mode_menu.dart';
import 'package:void_scriptor/core/theme/theme_preference_store.dart';

void main() {
  Future<(ThemePreferenceStore, ProviderContainer)> pumpMenu(
    WidgetTester tester,
  ) async {
    final store = InMemoryThemePreferenceStore();
    final container = ProviderContainer(
      overrides: [themePreferenceStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);
    await container.read(themeAccentControllerProvider.future);
    await container.read(themeControllerProvider.future);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: const Text('t')),
            body: const Align(
              alignment: Alignment.topRight,
              child: ThemeModeMenu(),
            ),
          ),
        ),
      ),
    );
    return (store, container);
  }

  Future<void> openMenu(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.palette_outlined));
    await tester.pumpAndSettle();
  }

  testWidgets('menu menampilkan submenu Accent color', (tester) async {
    await pumpMenu(tester);
    await openMenu(tester);
    expect(find.text('Accent color'), findsOneWidget);
    // Item mode lama tidak hilang.
    expect(find.text('Light'), findsWidgets);
    expect(find.text('Dark'), findsWidgets);
  });

  testWidgets('memilih Sage dari submenu mengubah + menyimpan aksen', (
    tester,
  ) async {
    final (store, container) = await pumpMenu(tester);
    await openMenu(tester);
    await tester.tap(find.text('Accent color'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sage'));
    await tester.pumpAndSettle();

    expect(
      container.read(themeAccentControllerProvider).value,
      VoidThemeAccent.sage,
    );
    expect(await store.loadAccent(), VoidThemeAccent.sage);
  });

  testWidgets('memilih mode tetap bekerja setelah submenu ada', (tester) async {
    final (store, container) = await pumpMenu(tester);
    await openMenu(tester);
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(container.read(themeControllerProvider).value, AppThemeMode.dark);
    expect(await store.load(), AppThemeMode.dark);
  });
}
