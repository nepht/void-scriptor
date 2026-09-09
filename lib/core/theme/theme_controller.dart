import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_theme_mode.dart';
import 'theme_preference_store.dart';

/// Mengelola mode tema aplikasi (system/light/dark) dan mempertahankan
/// pilihan pengguna.
class ThemeController extends AsyncNotifier<AppThemeMode> {
  @override
  Future<AppThemeMode> build() async {
    final store = ref.read(themePreferenceStoreProvider);
    final loaded = await store.load();
    return loaded ?? AppThemeMode.system;
  }

  Future<void> setMode(AppThemeMode mode) async {
    final store = ref.read(themePreferenceStoreProvider);
    await store.save(mode);
    state = AsyncData(mode);
  }
}

final themeControllerProvider =
    AsyncNotifierProvider<ThemeController, AppThemeMode>(ThemeController.new);

/// Mengelola aksen warna tema (voidPurple/ink/ember/sage/rose/ocean).
class ThemeAccentController extends AsyncNotifier<VoidThemeAccent> {
  @override
  Future<VoidThemeAccent> build() async {
    final store = ref.read(themePreferenceStoreProvider);
    final loaded = await store.loadAccent();
    return loaded ?? VoidThemeAccent.voidPurple;
  }

  Future<void> setAccent(VoidThemeAccent accent) async {
    final store = ref.read(themePreferenceStoreProvider);
    await store.saveAccent(accent);
    state = AsyncData(accent);
  }
}

final themeAccentControllerProvider =
    AsyncNotifierProvider<ThemeAccentController, VoidThemeAccent>(
      ThemeAccentController.new,
    );
