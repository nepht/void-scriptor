import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../domain/sync_models.dart';

/// Contract for pushing/pulling project state to/from a cloud backend (Step 29.4).
abstract interface class CloudSyncService {
  Future<Map<String, Object?>> pull(String projectId);
  Future<void> push({
    required String projectId,
    required Map<String, Object?> state,
  });
  Future<SyncResult> sync({
    required String projectId,
    required Map<String, Object?> local,
  });
}

/// Deterministic in-memory implementation for tests and offline preview
/// (Step 29.5).
class InMemoryCloudSyncService implements CloudSyncService {
  final _store = <String, Map<String, Object?>>{};

  @override
  Future<Map<String, Object?>> pull(String projectId) async =>
      Map<String, Object?>.from(_store[projectId] ?? const {});

  @override
  Future<void> push({
    required String projectId,
    required Map<String, Object?> state,
  }) async {
    _store[projectId] = Map<String, Object?>.from(state);
  }

  @override
  Future<SyncResult> sync({
    required String projectId,
    required Map<String, Object?> local,
  }) async {
    final remote = _store[projectId] ?? const <String, Object?>{};
    final merged = <String, Object?>{...remote, ...local};
    _store[projectId] = merged;
    return SyncResult(
      state: SyncState.synced,
      applied: merged.length,
      total: merged.length,
    );
  }
}

/// Filesystem-backed implementation that persists each project's remote state
/// as a JSON file (Step 29.5).
class FolderCloudSyncService implements CloudSyncService {
  FolderCloudSyncService(this.root);

  final Directory root;

  File _file(String projectId) => File(p.join(root.path, '$projectId.json'));

  @override
  Future<Map<String, Object?>> pull(String projectId) async {
    final file = _file(projectId);
    if (!await file.exists()) return const {};
    final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    return Map<String, Object?>.from(json);
  }

  @override
  Future<void> push({
    required String projectId,
    required Map<String, Object?> state,
  }) async {
    await root.create(recursive: true);
    await _file(projectId).writeAsString(jsonEncode(state));
  }

  @override
  Future<SyncResult> sync({
    required String projectId,
    required Map<String, Object?> local,
  }) async {
    final remote = await pull(projectId);
    final merged = <String, Object?>{...remote, ...local};
    await push(projectId: projectId, state: merged);
    return SyncResult(
      state: SyncState.synced,
      applied: merged.length,
      total: merged.length,
    );
  }
}
