import 'package:shared_preferences/shared_preferences.dart';

import '../domain/asset_search_query.dart';

abstract interface class AssetViewPreferenceStore {
  Future<AssetViewMode?> load();
  Future<void> save(AssetViewMode mode);
}

class SharedPreferencesAssetViewPreferenceStore
    implements AssetViewPreferenceStore {
  static const preferenceKey = 'asset_browser.view_mode';

  @override
  Future<AssetViewMode?> load() async {
    final value = (await SharedPreferences.getInstance()).getString(
      preferenceKey,
    );
    if (value == null) return null;
    for (final mode in AssetViewMode.values) {
      if (mode.name == value) return mode;
    }
    return null;
  }

  @override
  Future<void> save(AssetViewMode mode) async {
    await (await SharedPreferences.getInstance()).setString(
      preferenceKey,
      mode.name,
    );
  }
}

class InMemoryAssetViewPreferenceStore implements AssetViewPreferenceStore {
  AssetViewMode? _mode;

  @override
  Future<AssetViewMode?> load() async => _mode;

  @override
  Future<void> save(AssetViewMode mode) async => _mode = mode;
}
