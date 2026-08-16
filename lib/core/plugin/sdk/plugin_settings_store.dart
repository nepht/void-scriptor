/// In-memory key-value settings store per plugin (Step 31.5).
class PluginSettingsStore {
  final Map<String, String> _values = {};

  Future<void> set(String key, String value) async => _values[key] = value;
  Future<String?> get(String key) async => _values[key];
  Future<void> remove(String key) async => _values.remove(key);

  Map<String, String> snapshot() => Map.unmodifiable(_values);
}
