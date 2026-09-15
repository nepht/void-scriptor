import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../../core/project_package/project_package.dart';

class ProjectSnapshot {
  const ProjectSnapshot({
    required this.id,
    required this.projectId,
    required this.label,
    required this.assetType,
    required this.assetId,
    required this.createdAt,
    required this.data,
  });

  final String id;
  final String projectId;
  final String label;
  final String assetType;
  final String assetId;
  final DateTime createdAt;
  final Map<String, dynamic> data;
}

class VersionDiff {
  const VersionDiff({
    required this.added,
    required this.removed,
    required this.changed,
  });

  final Map<String, Object?> added;
  final Map<String, Object?> removed;
  final Map<String, Map<String, Object?>> changed;
}

class ProjectVersionControlService {
  ProjectVersionControlService(this.package);

  final ProjectPackage package;
  static const _uuid = Uuid();

  Directory get _directory => Directory(package.resolve('.versions'));

  Future<ProjectSnapshot> createSnapshot({
    required String label,
    required String assetType,
    required String assetId,
    required Map<String, Object?> data,
  }) async {
    await _directory.create(recursive: true);
    final snapshot = ProjectSnapshot(
      id: _uuid.v4(),
      projectId: package.projectId,
      label: label,
      assetType: assetType,
      assetId: assetId,
      createdAt: DateTime.now().toUtc(),
      data: Map<String, dynamic>.from(data),
    );
    final file = File(p.join(_directory.path, '${snapshot.id}.json'));
    await file.writeAsString(
      jsonEncode({
        'id': snapshot.id,
        'projectId': snapshot.projectId,
        'label': snapshot.label,
        'assetType': snapshot.assetType,
        'assetId': snapshot.assetId,
        'createdAt': snapshot.createdAt.toIso8601String(),
        'data': snapshot.data,
      }),
    );
    return snapshot;
  }

  Future<List<ProjectSnapshot>> listSnapshots() async {
    if (!await _directory.exists()) return const [];
    final files = await _directory
        .list()
        .where((entity) => entity is File && entity.path.endsWith('.json'))
        .cast<File>()
        .toList();
    final snapshots = <ProjectSnapshot>[];
    for (final file in files) {
      snapshots.add(await _read(file));
    }
    snapshots.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return snapshots;
  }

  Future<VersionDiff> compare(String firstId, String secondId) async {
    final first = await _readById(firstId);
    final second = await _readById(secondId);
    final added = <String, Object?>{};
    final removed = <String, Object?>{};
    final changed = <String, Map<String, Object?>>{};
    for (final key in second.data.keys) {
      if (!first.data.containsKey(key)) {
        added[key] = second.data[key];
      } else if (!_jsonEquals(first.data[key], second.data[key])) {
        changed[key] = {'before': first.data[key], 'after': second.data[key]};
      }
    }
    for (final key in first.data.keys) {
      if (!second.data.containsKey(key)) removed[key] = first.data[key];
    }
    return VersionDiff(added: added, removed: removed, changed: changed);
  }

  Future<void> restore(
    String snapshotId,
    Future<void> Function(Map<String, Object?> data) apply,
  ) async {
    final snapshot = await _readById(snapshotId);
    await apply(Map<String, Object?>.from(snapshot.data));
  }

  Future<int> prune(int retain) async {
    if (retain < 0) throw ArgumentError.value(retain, 'retain');
    final snapshots = await listSnapshots();
    final removed = snapshots.skip(retain).toList();
    for (final snapshot in removed) {
      final file = File(p.join(_directory.path, '${snapshot.id}.json'));
      if (await file.exists()) {
        await file.delete();
      }
    }
    return removed.length;
  }

  Future<ProjectSnapshot> _readById(String id) async =>
      _read(File(p.join(_directory.path, '$id.json')));

  /// Structural JSON equality (vs-hunt-20260915-resilience BUG-9).
  ///
  /// Snapshot data is decoded from separate JSON files, so nested maps and
  /// lists never share identity even when their contents are equal. Dart's
  /// default `==` on collections is identity-based, so a shallow `!=` marked
  /// unchanged nested structures as modified. This compares recursively:
  /// maps match key-wise regardless of insertion order, lists match
  /// position-wise, and every other value falls back to plain equality.
  static bool _jsonEquals(Object? first, Object? second) {
    if (identical(first, second)) return true;
    if (first is Map && second is Map) {
      if (first.length != second.length) return false;
      for (final entry in first.entries) {
        if (!second.containsKey(entry.key)) return false;
        if (!_jsonEquals(entry.value, second[entry.key])) return false;
      }
      return true;
    }
    if (first is List && second is List) {
      if (first.length != second.length) return false;
      for (var i = 0; i < first.length; i++) {
        if (!_jsonEquals(first[i], second[i])) return false;
      }
      return true;
    }
    return first == second;
  }

  Future<ProjectSnapshot> _read(File file) async {
    if (!await file.exists()) {
      throw StateError('Snapshot not found: ${file.path}');
    }
    final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    return ProjectSnapshot(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      label: json['label'] as String,
      assetType: json['assetType'] as String,
      assetId: json['assetId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      data: Map<String, dynamic>.from(json['data'] as Map),
    );
  }
}
