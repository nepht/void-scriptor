/// Local-only usage journal for Void Scriptor v1.2 (Sprint 109, decision M2).
///
/// Privacy contract (docs/discovery/v1.2 + docs/planning/v1.2/
/// permission_privacy_model.md): opt-in (default OFF), metadata-only,
/// anti-leakage BY CONSTRUCTION — only whitelisted event types exist and only
/// whitelisted field keys are ever stored. Creative content can therefore not
/// reach the journal even if a caller passes it.
library;

import 'dart:convert';
import 'dart:io';

/// The only event types the journal accepts.
const Set<String> kLocalUsageEventTypes = <String>{
  'app_open',
  'project_opened',
  'feature_surface_viewed',
  'flag_changed',
  'export_run',
  'share_created',
  'analysis_run',
  'journal_opted_in',
  'journal_opted_out',
};

/// The only field keys ever stored. Anything else is silently dropped.
const Set<String> kAllowedJournalFieldKeys = <String>{
  'flag',
  'outcome',
  'surface',
  'durationMs',
  'count',
  'format',
  'reasonCode',
  'schemaVersion',
};

const int _maxEntries = 5000;
const String _fileName = 'usage_journal.json';

final class LocalUsageEntry {
  const LocalUsageEntry({
    required this.timestampUtc,
    required this.eventType,
    required this.fields,
  });

  factory LocalUsageEntry.fromJson(Map<String, dynamic> json) =>
      LocalUsageEntry(
        timestampUtc: DateTime.parse(json['ts'] as String).toUtc(),
        eventType: json['type'] as String,
        fields: Map<String, Object?>.from(json['fields'] as Map),
      );

  final DateTime timestampUtc;
  final String eventType;
  final Map<String, Object?> fields;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'ts': timestampUtc.toIso8601String(),
    'type': eventType,
    'fields': fields,
  };
}

/// Opt-in local usage journal. Instances persist to a single JSON file inside
/// [storageDirectory] when configured; persistence calls without a configured
/// directory throw [StateError] instead of guessing a host path.
final class LocalUsageJournal {
  LocalUsageJournal({this.storageDirectory});

  final Directory? storageDirectory;

  bool _enabled = false;
  final List<LocalUsageEntry> _entries = <LocalUsageEntry>[];

  bool get enabled => _enabled;

  set enabled(bool value) {
    if (_enabled == value) return;
    _enabled = value;
    if (value) {
      // Privacy audit trail: the journal records its own lifecycle.
      _append('journal_opted_in', const {});
    }
  }

  List<LocalUsageEntry> get entries => List<LocalUsageEntry>.unmodifiable(
    _enabled ? _entries : const <LocalUsageEntry>[],
  );

  void record(String eventType, {Map<String, Object?> fields = const {}}) {
    if (!kLocalUsageEventTypes.contains(eventType)) {
      throw ArgumentError.value(eventType, 'eventType', 'Unknown event type');
    }
    if (!_enabled) return;
    _append(eventType, fields);
  }

  void clear() => _entries.clear();

  File get _file {
    final dir = storageDirectory;
    if (dir == null) {
      throw StateError('LocalUsageJournal.storageDirectory is not configured');
    }
    return File('${dir.path}/$_fileName');
  }

  Future<void> save() async {
    final payload = jsonEncode(<String, dynamic>{
      'schemaVersion': 1,
      'enabled': _enabled,
      'entries': _entries.map((e) => e.toJson()).toList(),
    });
    await _file.writeAsString(payload, flush: true);
  }

  Future<void> load() async {
    final file = _file;
    if (!await file.exists()) return;
    try {
      final json = jsonDecode(await file.readAsString());
      if (json is! Map<String, dynamic>) return;
      _enabled = json['enabled'] == true;
      final rawEntries = json['entries'];
      if (rawEntries is! List) return;
      _entries
        ..clear()
        ..addAll(
          rawEntries.whereType<Map<String, dynamic>>().map(
            LocalUsageEntry.fromJson,
          ),
        );
    } on FormatException {
      // Corrupt file degrades to an empty disabled journal, never a crash.
      _enabled = false;
      _entries.clear();
    }
  }

  void _append(String eventType, Map<String, Object?> fields) {
    _entries.add(
      LocalUsageEntry(
        timestampUtc: DateTime.now().toUtc(),
        eventType: eventType,
        fields: Map<String, Object?>.fromEntries(
          fields.entries.where((e) => kAllowedJournalFieldKeys.contains(e.key)),
        ),
      ),
    );
    if (_entries.length > _maxEntries) {
      _entries.removeRange(0, _entries.length - _maxEntries);
    }
  }
}
