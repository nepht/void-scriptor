import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Durable draft journal (Step 145.30 autosave recovery).
///
/// Menyimpan draf yang belum tersimpan durable ke file JSON per scene di
/// dalam direktori proyek (`recovery/draft-journal/`). Tulisan bersifat
/// atomic: konten ditulis ke `<scene>.json.tmp`, di-flush, lalu di-rename
/// ke `<scene>.json` sehingga crash/power-loss tidak meninggalkan file
/// setengah jadi. `acknowledge` menghapus entri hanya SETELAH autosave
/// durable sukses (no silent loss).
class DurableDraftJournal {
  DurableDraftJournal({required this._dir, DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final Directory _dir;
  final DateTime Function() _clock;
  bool _closed = false;

  File _entryFile(String sceneId) =>
      File(p.join(_dir.path, '${_safeSceneId(sceneId)}.json'));

  String _safeSceneId(String sceneId) =>
      sceneId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');

  /// Menyimpan (atomically) konten draf [sceneId] yang belum autosave.
  /// Stage ulang untuk scene yang sama menimpa entri dengan konten
  /// terbaru (hanya versi terbaru yang perlu dipulihkan).
  Future<void> stage({required String sceneId, required String content}) async {
    if (content.trim().isEmpty) {
      throw ArgumentError('journal content must not be blank');
    }
    if (_closed) {
      throw StateError('journal is closed');
    }
    await _dir.create(recursive: true);
    final temp = File('${_entryFile(sceneId).path}.tmp');
    final payload = jsonEncode(<String, Object?>{
      'sceneId': sceneId,
      'content': content,
      'stagedAt': _clock().toUtc().toIso8601String(),
    });
    final sink = temp.openWrite(mode: FileMode.write);
    try {
      sink.write(payload);
      await sink.flush();
      await sink.close();
    } on Exception {
      try {
        await sink.close();
      } on Exception {
        // best-effort close; rename berikut tidak akan dilakukan
      }
      rethrow;
    }
    await temp.rename(_entryFile(sceneId).path);
  }

  /// Daftar draf yang belum di-acknowledge (urut nama scene, deterministik).
  Future<List<PendingDraftEntry>> pendingEntries() async {
    if (!await _dir.exists()) return const <PendingDraftEntry>[];
    final entries = <PendingDraftEntry>[];
    await for (final entity in _dir.list()) {
      if (entity is! File) continue;
      if (!entity.path.endsWith('.json')) continue;
      try {
        final decoded =
            jsonDecode(await entity.readAsString()) as Map<String, dynamic>;
        final sceneId = decoded['sceneId'] as String?;
        final content = decoded['content'] as String?;
        if (sceneId == null || sceneId.isEmpty) continue;
        if (content == null) continue;
        entries.add(
          PendingDraftEntry(
            sceneId: sceneId,
            content: content,
            stagedAt: DateTime.tryParse(decoded['stagedAt'] as String? ?? ''),
          ),
        );
      } on FormatException {
        // Entri korup (crash sebelum rename selesai) diabaikan: file
        // .tmp setengah jadi tidak pernah dianggap sumber pemulihan.
        continue;
      }
    }
    entries.sort((a, b) => a.sceneId.compareTo(b.sceneId));
    return entries;
  }

  /// Menghapus entri journal SETELAH konten tersimpan durable.
  Future<void> acknowledge(String sceneId) async {
    final file = _entryFile(sceneId);
    if (await file.exists()) await file.delete();
  }

  Future<void> close() async {
    _closed = true;
  }
}

/// Satu entri draf yang belum tersimpan; dibaca dari journal durable.
class PendingDraftEntry {
  const PendingDraftEntry({
    required this.sceneId,
    required this.content,
    required this.stagedAt,
  });

  final String sceneId;
  final String content;
  final DateTime? stagedAt;
}
