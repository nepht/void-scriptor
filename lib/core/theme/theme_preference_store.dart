import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme_mode.dart';

/// Penyimpanan preferensi tema aplikasi (mode kecerahan + aksen warna).
abstract interface class ThemePreferenceStore {
  /// Mengembalikan `null` jika belum pernah disimpan (default = system).
  Future<AppThemeMode?> load();
  Future<void> save(AppThemeMode mode);

  /// Aksen warna terpilih; `null` = belum pernah memilih (default voidPurple).
  Future<VoidThemeAccent?> loadAccent();
  Future<void> saveAccent(VoidThemeAccent accent);
}

class SharedPreferencesThemePreferenceStore implements ThemePreferenceStore {
  static const preferenceKey = 'appearance.theme_mode';
  static const accentKey = 'appearance.theme_accent';

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

  @override
  Future<VoidThemeAccent?> loadAccent() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(accentKey);
    if (value == null) return null;
    for (final accent in VoidThemeAccent.values) {
      if (accent.name == value) return accent;
    }
    return null;
  }

  @override
  Future<void> saveAccent(VoidThemeAccent accent) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(accentKey, accent.name);
  }
}

class InMemoryThemePreferenceStore implements ThemePreferenceStore {
  AppThemeMode? _mode;
  VoidThemeAccent? _accent;

  @override
  Future<AppThemeMode?> load() async => _mode;

  @override
  Future<void> save(AppThemeMode mode) async => _mode = mode;

  @override
  Future<VoidThemeAccent?> loadAccent() async => _accent;

  @override
  Future<void> saveAccent(VoidThemeAccent accent) async => _accent = accent;
}

final themePreferenceStoreProvider = Provider<ThemePreferenceStore>(
  (ref) => SharedPreferencesThemePreferenceStore(),
);
