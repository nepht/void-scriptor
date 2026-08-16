import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/theme/app_theme_mode.dart';
import 'package:void_scriptor/core/theme/theme_controller.dart';
import 'package:void_scriptor/core/theme/theme_preference_store.dart';

void main() {
  ProviderContainer makeContainer(ThemePreferenceStore store) {
    final container = ProviderContainer(
      overrides: [themePreferenceStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test(
    'default tema adalah system ketika tidak ada preferensi tersimpan',
    () async {
      final container = makeContainer(InMemoryThemePreferenceStore());

      final value = await container.read(themeControllerProvider.future);

      expect(value, AppThemeMode.system);
    },
  );

  test('AppThemeMode memetakan ke ThemeMode Flutter dengan benar', () {
    expect(AppThemeMode.system.themeMode, ThemeMode.system);
    expect(AppThemeMode.light.themeMode, ThemeMode.light);
    expect(AppThemeMode.dark.themeMode, ThemeMode.dark);
  });

  test('setMode terang memperbarui state dan menyimpan preferensi', () async {
    final store = InMemoryThemePreferenceStore();
    final container = makeContainer(store);
    await container.read(themeControllerProvider.future);

    await container
        .read(themeControllerProvider.notifier)
        .setMode(AppThemeMode.light);

    expect(container.read(themeControllerProvider).value, AppThemeMode.light);
    expect(await store.load(), AppThemeMode.light);
  });

  test('setMode gelap memperbarui state dan menyimpan preferensi', () async {
    final store = InMemoryThemePreferenceStore();
    final container = makeContainer(store);
    await container.read(themeControllerProvider.future);

    await container
        .read(themeControllerProvider.notifier)
        .setMode(AppThemeMode.dark);

    expect(container.read(themeControllerProvider).value, AppThemeMode.dark);
    expect(await store.load(), AppThemeMode.dark);
  });

  test('memuat preferensi tersimpan (dark) saat startup', () async {
    final store = InMemoryThemePreferenceStore();
    await store.save(AppThemeMode.dark);
    final container = makeContainer(store);

    final value = await container.read(themeControllerProvider.future);

    expect(value, AppThemeMode.dark);
  });
}
