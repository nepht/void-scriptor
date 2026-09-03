import 'dart:convert';
import 'dart:io';

import '../domain/sync_authority_policy.dart';

/// Persistensi authority sync per proyek (Sprint 145.32).
///
/// File JSON v1 per proyek, ditulis atomik (tmp + rename) sehingga crash
/// di tengah penulisan tidak meninggalkan authority setengah jadi. File
/// rusak atau hilang dibaca sebagai "tidak ada ownership tersimpan" —
/// bukan error, agar proyek tetap dapat dibuka.
class SyncAuthorityStore {
  SyncAuthorityStore({required Directory rootDirectory})
    : _root = rootDirectory;

  final Directory _root;

  File _fileFor(String projectId) {
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
    return File(
      '${_root.path}${Platform.pathSeparator}sync_authority_$id.json',
    );
  }

  Future<void> save(String projectId, SyncAuthority authority) async {
    final file = _fileFor(projectId);
    await _root.create(recursive: true);
    final payload = jsonEncode({'schema': 1, 'authority': authority.name});
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(payload, flush: true);
    await tmp.rename(file.path);
  }

  Future<SyncAuthority?> load(String projectId) async {
    final file = _fileFor(projectId);
    if (!await file.exists()) {
      return null;
    }
    try {
      final data = jsonDecode(await file.readAsString());
      if (data is! Map<String, dynamic>) {
        return null;
      }
      if (data['schema'] != 1) {
        return null;
      }
      final name = data['authority'];
      for (final authority in SyncAuthority.values) {
        if (authority.name == name) {
          return authority;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> clear(String projectId) async {
    final file = _fileFor(projectId);
    if (await file.exists()) {
      await file.delete();
    }
  }
}

/// Arbitrase authority yang bertahan lintas proses: keputusan claim tetap
/// milik [SingleSyncAuthorityPolicy], sementara ownership yang disetujui
/// dipersist ke [SyncAuthorityStore] dan dipulihkan saat proses berikutnya.
class PersistedSyncAuthority {
  PersistedSyncAuthority({required this._store});

  final SyncAuthorityStore _store;
  final Map<String, SingleSyncAuthorityPolicy> _policies = {};

  SingleSyncAuthorityPolicy _policyFor(String projectId) =>
      _policies.putIfAbsent(projectId, SingleSyncAuthorityPolicy.new);

  Future<SyncAuthorityDecision> claim(
    String projectId,
    SyncAuthority authority,
  ) async {
    final decision = _policyFor(projectId).claim(authority);
    if (decision.allowed) {
      await _store.save(projectId, authority);
    }
    return decision;
  }

  Future<void> restore(String projectId) async {
    final persisted = await _store.load(projectId);
    if (persisted != null) {
      _policyFor(projectId).claim(persisted);
    }
  }

  Future<void> release(String projectId) async {
    _policyFor(projectId).release();
    await _store.clear(projectId);
  }
}
