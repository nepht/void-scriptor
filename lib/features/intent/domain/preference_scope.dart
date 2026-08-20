enum PreferenceScope { session, project, global }

class ScopedIntentPreferences {
  final Map<PreferenceScope, Map<String, Object?>> _values = {
    for (final scope in PreferenceScope.values) scope: <String, Object?>{},
  };

  Object? get(String key, {PreferenceScope scope = PreferenceScope.session}) {
    _validateKey(key);
    return _values[scope]![key];
  }

  void set(
    String key,
    Object? value, {
    PreferenceScope scope = PreferenceScope.session,
  }) {
    _validateKey(key);
    _values[scope]![key] = value;
  }

  void clear({PreferenceScope scope = PreferenceScope.session}) {
    _values[scope]!.clear();
  }

  static void _validateKey(String key) {
    if (key.trim().isEmpty) {
      throw ArgumentError.value(key, 'key', 'must not be blank');
    }
  }
}
