/// Sprint 145.39 — Non-Core Preservation and Disablement.
///
/// Persistence for v1.2 feature flag overrides. The in-memory
/// [FeatureFlagRegistry] stays the single runtime primitive; this store owns
/// only the durable projection of the enabled-flag set so a restart observes
/// the user's overrides instead of silently resetting them to OFF.
///
/// File contract: `<directory>/feature_flag_overrides.json`,
/// `{"schema": 1, "overrides": {"<flag>": true}}` written atomically
/// (tmp file + rename, no residue). Unknown flag names in the file are
/// dropped on load (no silent fixup) and rejected on save, mirroring the
/// registry's `ArgumentError` contract. A corrupt or missing file means
/// clean defaults — never a crash at startup.
library;

import 'dart:collection';
import 'dart:convert';
import 'dart:io';

class FeatureFlagOverrideStore {
  FeatureFlagOverrideStore({
    required this._directory,
    required List<String> knownFlags,
  }) : _knownFlags = Set<String>.from(knownFlags) {
    _load();
  }

  /// Canonical override file name inside [directory].
  String get fileName => fileNameConst;

  static const String fileNameConst = 'feature_flag_overrides.json';

  final Directory _directory;
  final Set<String> _knownFlags;
  Set<String> _enabled = <String>{};

  /// Currently persisted enabled flags (unmodifiable view).
  List<String> get enabledOverrides => List<String>.unmodifiable(_enabled);

  /// Atomically replaces the persisted enabled set. Throws ArgumentError
  /// for unknown flags; writes tmp then renames so a crash never leaves a
  /// half-written override file.
  void saveOverrides(Iterable<String> flags) {
    final next = LinkedHashSet<String>.from(flags);
    for (final flag in next) {
      if (!_knownFlags.contains(flag)) {
        throw ArgumentError.value(flag, 'flag', 'Unknown v1.2 feature flag');
      }
    }

    final file = File('${_directory.path}${Platform.pathSeparator}$fileName');
    _directory.createSync(recursive: true);
    final tmp = File('${file.path}.tmp');
    tmp.writeAsStringSync(
      jsonEncode(<String, dynamic>{
        'schema': 1,
        'overrides': <String, bool>{for (final f in next) f: true},
      }),
      flush: true,
    );
    tmp.renameSync(file.path);
    _enabled = next;
  }

  void _load() {
    final file = File('${_directory.path}${Platform.pathSeparator}$fileName');
    if (!file.existsSync()) {
      _enabled = <String>{};
      return;
    }
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is Map && decoded['overrides'] is Map) {
        final raw = decoded['overrides'] as Map<dynamic, dynamic>;
        _enabled = LinkedHashSet<String>.from(
          raw.keys.whereType<String>().where(_knownFlags.contains),
        );
      } else {
        _enabled = <String>{};
      }
    } on FormatException {
      _enabled = <String>{};
    }
  }
}
