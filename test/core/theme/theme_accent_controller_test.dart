// Pilihan warna aksen tema: default voidPurple, tersimpan lintas sesuai.
//
// Kebutuhan Choi: banyak pilihan warna agar tidak monoton, sesuai selera
// penulis. Additive terhadap ThemeMode eksisting — test lama tak boleh pecah.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/theme/app_theme_mode.dart';
import 'package:void_scriptor/core/theme/theme_controller.dart';
import 'package:void_scriptor/core/theme/theme_preference_store.dart';

void main() {
  group('ThemePreferenceStore accent', () {
    test('loadAccent default null (belum pernah memilih)', () async {
      final store = InMemoryThemePreferenceStore();
      expect(await store.loadAccent(), isNull);
    });

    test('saveAccent/loadAccent roundtrip', () async {
      final store = InMemoryThemePreferenceStore();
      await store.saveAccent(VoidThemeAccent.ocean);
      expect(await store.loadAccent(), VoidThemeAccent.ocean);
      await store.saveAccent(VoidThemeAccent.ember);
      expect(await store.loadAccent(), VoidThemeAccent.ember);
    });
  });

  group('ThemeAccentController', () {
    test('default accent = voidPurple', () async {
      final container = ProviderContainer(
        overrides: [
          themePreferenceStoreProvider.overrideWithValue(
            InMemoryThemePreferenceStore(),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(themeAccentControllerProvider.future);
      expect(
        container.read(themeAccentControllerProvider).value,
        VoidThemeAccent.voidPurple,
      );
    });

    test('setAccent memperbarui state dan tersimpan di store', () async {
      final store = InMemoryThemePreferenceStore();
      final container = ProviderContainer(
        overrides: [themePreferenceStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);

      final controller = container.read(themeAccentControllerProvider.notifier);
      await container.read(themeAccentControllerProvider.future);

      await controller.setAccent(VoidThemeAccent.ocean);
      expect(
        container.read(themeAccentControllerProvider).value,
        VoidThemeAccent.ocean,
      );
      expect(await store.loadAccent(), VoidThemeAccent.ocean);

      // Mode tema tidak terpengaruh (independen)
      expect(await store.load(), isNull);
    });
  });
}
