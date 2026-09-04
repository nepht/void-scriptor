import 'dart:convert';
import 'dart:io';

import '../domain/sync_authority_policy.dart';
import '../domain/sync_models.dart';

/// One parked local change that could not be pushed because the project was
/// owned by the other sync authority (Sprint 145.32 conflict flow).
class SyncAuthorityJournalEntry {
  const SyncAuthorityJournalEntry({
    required this.id,
    required this.projectId,
    required this.authority,
    required this.reason,
    required this.local,
    this.base = const {},
    required this.createdAt,
  });

  final String id;
  final String projectId;
  final SyncAuthority authority;
  final String reason;
  final Map<String, Object?> local;

  /// Remote state observed when the entry was parked, if any. Kept so the
  /// later drain can perform a three-way merge instead of blind overwrite.
  final Map<String, Object?> base;
  final DateTime createdAt;

  Map<String, Object?> toJson() => <String, Object?>{
    'schema': 1,
    'id': id,
    'projectId': projectId,
    'authority': authority.name,
    'reason': reason,
    'local': local,
    'base': base,
    'createdAt': createdAt.toUtc().toIso8601String(),
  };

  static SyncAuthorityJournalEntry? tryParse(String line) {
    if (line.trim().isEmpty) {
      return null;
    }
    final Object? data;
    try {
      data = jsonDecode(line);
    } catch (_) {
      return null;
    }
    if (data is! Map<String, dynamic>) {
      return null;
    }
    if (data['schema'] != 1) {
      return null;
    }
    final id = data['id'];
    final projectId = data['projectId'];
    final reason = data['reason'];
    final local = data['local'];
    final base = data['base'];
    final createdAt = data['createdAt'];
    if (id is! String ||
        id.isEmpty ||
        projectId is! String ||
        projectId.isEmpty ||
        reason is! String ||
        local is! Map<String, dynamic>) {
      return null;
    }
    if (base != null && base is! Map<String, dynamic>) {
      return null;
    }
    final parsedDate = DateTime.tryParse(createdAt is String ? createdAt : '');
    if (parsedDate == null) {
      return null;
    }
    SyncAuthority? authority;
    for (final value in SyncAuthority.values) {
      if (value.name == data['authority']) {
        authority = value;
      }
    }
    if (authority == null) {
      return null;
    }
    return SyncAuthorityJournalEntry(
      id: id,
      projectId: projectId,
      authority: authority,
      reason: reason,
      local: Map<String, Object?>.from(local),
      base: base == null
          ? const <String, Object?>{}
          : Map<String, Object?>.from(base),
      createdAt: parsedDate,
    );
  }
}

/// Outcome of draining parked authority-conflict changes.
class SyncDrainOutcome {
  const SyncDrainOutcome({
    required this.applied,
    required this.remaining,
    required this.conflictKeys,
  });

  final int applied;
  final int remaining;
  final Set<String> conflictKeys;

  bool get hasConflicts => conflictKeys.isNotEmpty;
}

/// Durable journal for the 145.32 authority conflict flow.
///
/// When a sync write is denied because cloud and external folder cannot
/// concurrently own one live project, the denied local change is PARKED here
/// instead of being silently discarded. Entries survive a restart, corrupt
/// lines are quarantined (never dropped), and drain performs a three-way
/// merge once the conflict is gone: keys where remote and local both diverged
/// from the recorded base stay pending, everything else is handed to the
/// apply callback and removed from the journal only after apply completes.
class SyncAuthorityConflictJournal {
  SyncAuthorityConflictJournal({required Directory rootDirectory})
    : _root = rootDirectory;

  final Directory _root;

  File _fileFor(String projectId) {
    final id = _safeProjectId(projectId);
    return File(
      '${_root.path}${Platform.pathSeparator}sync_authority_journal_$id.jsonl',
    );
  }

  File _quarantineFileFor(String projectId) {
    final id = _safeProjectId(projectId);
    return File(
      '${_root.path}${Platform.pathSeparator}'
      'sync_authority_journal_$id.quarantine.jsonl',
    );
  }

  String _safeProjectId(String projectId) {
    final id = projectId.trim();
    if (id.isEmpty) {
      throw ArgumentError.value(projectId, 'projectId', 'cannot be empty');
    }
    if (id.contains('/') || id.contains(String.fromCharCode(92))) {
      throw ArgumentError.value(
        projectId,
        'projectId',
        'must not contain path separators',
      );
    }
    return id;
  }

  Future<SyncResult> park({
    required String projectId,
    required SyncAuthority authority,
    required String reason,
    required Map<String, Object?> local,
    Map<String, Object?> base = const {},
  }) async {
    final entry = SyncAuthorityJournalEntry(
      id:
          DateTime.now().microsecondsSinceEpoch.toRadixString(36) +
          local.hashCode.toRadixString(36),
      projectId: _safeProjectId(projectId),
      authority: authority,
      reason: reason,
      local: Map<String, Object?>.from(local),
      base: Map<String, Object?>.from(base),
      createdAt: DateTime.now().toUtc(),
    );
    final file = _fileFor(entry.projectId);
    await _root.create(recursive: true);
    final existing = await file.exists() ? await file.readAsString() : '';
    final buffer = StringBuffer(existing);
    if (existing.isNotEmpty && !existing.endsWith('\n')) {
      buffer.writeln();
    }
    buffer.writeln(jsonEncode(entry.toJson()));
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(buffer.toString(), flush: true);
    await tmp.rename(file.path);
    return SyncResult(
      state: SyncState.conflict,
      applied: 0,
      total: local.length,
      conflictKeys: Set<String>.from(local.keys),
      message:
          '$reason. Local changes preserved locally and queued for the '
          'next sync after the authority conflict is resolved.',
    );
  }

  Future<List<SyncAuthorityJournalEntry>> pending(String projectId) async {
    final (entries, _) = await _read(projectId);
    return entries;
  }

  Future<int> quarantined(String projectId) async {
    final file = _quarantineFileFor(projectId);
    if (!await file.exists()) {
      return 0;
    }
    final content = await file.readAsString();
    return content.split('\n').where((line) => line.trim().isNotEmpty).length;
  }

  Future<SyncDrainOutcome> drain({
    required String projectId,
    required Map<String, Object?> remote,
    required Future<void> Function(Map<String, Object?> merged) apply,
  }) async {
    final safeId = _safeProjectId(projectId);
    final (entries, rawLines) = await _read(safeId);
    if (entries.isEmpty) {
      return const SyncDrainOutcome(applied: 0, remaining: 0, conflictKeys: {});
    }

    final conflictKeys = <String>{};
    final appliedLines = <String>{};
    var appliedCount = 0;

    for (final (raw, entry) in rawLines) {
      if (entry == null) {
        // Corrupt line: already quarantined below, never silently dropped.
        continue;
      }
      final change = SyncChangeSet(
        base: entry.base,
        ours: remote,
        theirs: entry.local,
      );
      final conflicts = <String>{
        ...change.changedKeys,
      }.where(change.isConflictOn).toSet();
      if (conflicts.isNotEmpty) {
        conflictKeys.addAll(conflicts);
        // Stays pending until the divergence is resolved by the user.
        continue;
      }
      final merged = <String, Object?>{...remote, ...entry.local};
      await apply(merged);
      appliedCount += 1;
      appliedLines.add(raw);
    }

    if (appliedLines.isNotEmpty) {
      final file = _fileFor(safeId);
      final remainingLines = rawLines
          .map((pair) => pair.$1)
          .where((line) => !appliedLines.contains(line))
          .toList();
      final tmp = File('${file.path}.tmp');
      await tmp.writeAsString(
        remainingLines.isEmpty ? '' : '${remainingLines.join('\n')}\n',
        flush: true,
      );
      await tmp.rename(file.path);
    }

    return SyncDrainOutcome(
      applied: appliedCount,
      remaining: entries.length - appliedCount,
      conflictKeys: conflictKeys,
    );
  }

  Future<
    (
      List<SyncAuthorityJournalEntry>,
      List<(String, SyncAuthorityJournalEntry?)>,
    )
  >
  _read(String projectId) async {
    final file = _fileFor(projectId);
    if (!await file.exists()) {
      return (
        const <SyncAuthorityJournalEntry>[],
        const <(String, SyncAuthorityJournalEntry?)>[],
      );
    }
    final content = await file.readAsString();
    final entries = <SyncAuthorityJournalEntry>[];
    final rawLines = <(String, SyncAuthorityJournalEntry?)>[];
    final corruptLines = <String>[];
    for (final line in content.split('\n')) {
      if (line.trim().isEmpty) {
        continue;
      }
      final entry = SyncAuthorityJournalEntry.tryParse(line);
      if (entry == null) {
        corruptLines.add(line);
        rawLines.add((line, null));
      } else {
        entries.add(entry);
        rawLines.add((line, entry));
      }
    }
    if (corruptLines.isNotEmpty) {
      await _quarantineCorrupt(projectId, corruptLines);
    }
    return (entries, rawLines);
  }

  Future<void> _quarantineCorrupt(
    String projectId,
    List<String> corruptLines,
  ) async {
    final quarantine = _quarantineFileFor(projectId);
    await _root.create(recursive: true);
    final existingLines = <String>{};
    if (await quarantine.exists()) {
      for (final line in (await quarantine.readAsString()).split('\n')) {
        if (line.trim().isNotEmpty) {
          existingLines.add(line);
        }
      }
    }
    final missing = corruptLines.where((line) => !existingLines.contains(line));
    if (missing.isEmpty) {
      return;
    }
    final current = await quarantine.exists()
        ? await quarantine.readAsString()
        : '';
    final merged = StringBuffer(current);
    if (current.isNotEmpty && !current.endsWith('\n')) {
      merged.writeln();
    }
    for (final line in missing) {
      merged.writeln(line);
    }
    final tmp = File('${quarantine.path}.tmp');
    await tmp.writeAsString(merged.toString(), flush: true);
    await tmp.rename(quarantine.path);
  }
}
