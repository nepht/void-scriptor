import 'package:flutter_riverpod/misc.dart';
import 'package:void_scriptor/core/theme/theme_preference_store.dart';

/// Override penyimpanan tema agar test tidak menyentuh `SharedPreferences`
/// (plugin asli tidak tersedia di test environment).
List<Override> themeTestOverrides() => [
  themePreferenceStoreProvider.overrideWithValue(
    InMemoryThemePreferenceStore(),
  ),
];
