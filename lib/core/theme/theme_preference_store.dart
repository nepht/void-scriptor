import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme_mode.dart';

/// Penyimpanan preferensi tema aplikasi.
abstract interface class ThemePreferenceStore {
  /// Mengembalikan `null` jika belum pernah disimpan (default = system).
  Future<AppThemeMode?> load();
  Future<void> save(AppThemeMode mode);
}

class SharedPreferencesThemePreferenceStore implements ThemePreferenceStore {
  static const preferenceKey = 'appearance.theme_mode';

  @override
  Future<AppThemeMode?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(preferenceKey);
    if (value == null) return null;
    for (final mode in AppThemeMode.values) {
      if (mode.name == value) return mode;
    }
    return null;
  }

  @override
  Future<void> save(AppThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(preferenceKey, mode.name);
  }
}

class InMemoryThemePreferenceStore implements ThemePreferenceStore {
  AppThemeMode? _mode;

  @override
  Future<AppThemeMode?> load() async => _mode;

  @override
  Future<void> save(AppThemeMode mode) async => _mode = mode;
}

final themePreferenceStoreProvider = Provider<ThemePreferenceStore>(
  (ref) => SharedPreferencesThemePreferenceStore(),
);
