import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_theme_mode.dart';
import 'theme_preference_store.dart';

/// Mengelola mode tema aplikasi dan mempertahankan pilihan pengguna.
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
