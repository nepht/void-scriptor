import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Durable draft journal (Step 145.30 autosave recovery).
///
/// Menyimpan draf yang belum tersimpan durable ke file JSON per scene di
/// dalam direktori proyek (`recovery/draft-journal/`). Tulisan bersifat
/// atomic: konten ditulis ke `<scene>.json.tmp`, di-flush, lalu di-rename
/// ke `<scene>.json`. Rename memberikan jaminan file final tidak pernah
/// "setengah jadi" bila proses tulis selesai normal; Namun demikian,
/// power-loss/crash di jendela tulis tetap dapat meninggalkan file final
/// yang terpotong — entri semacam itu TIDAK dibuang diam-diam:
/// `pendingEntries()` men-surface-nya sebagai entri `isCorrupt` agar panel
/// DRAFT RECOVERY menampilkan statusnya (no silent loss). Sumber pemulihan
/// yang sah hanya file final; artefak `.tmp` in-progress selalu diabaikan.
/// Catatan batas platform: `flush()` dart:io tidak menjamin fsync
/// OS-level/directory-entry, jadi kehilangan data saat power-loss total
/// tidak sepenuhnya dapat dihilangkan di layer ini.
///
/// Artefak `.json.tmp` dari writer yang mati setelah flush namun sebelum
/// rename akan menjadi orphan permanen (bukan sumber pemulihan). Sweep
/// age-gated sekali-di-instance pada `pendingEntries()` membersihkannya
/// (bug-hunt-run128 BUG-3): hanya `.tmp` berumur >= [staleTmpThreshold]
/// yang dihapus, sehingga jendela tulis writer hidup tidak pernah
/// tersentuh dan file final tidak pernah menjadi sasaran sweep.
class DurableDraftJournal {
  DurableDraftJournal({required this._dir, DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final Directory _dir;
  final DateTime Function() _clock;
  bool _closed = false;

  /// Ambang umur sweep `.tmp`: jauh di atas jendela tulis normal
  /// (milidetik), di bawah rentang orphan crash yang layak dibersihkan.
  static const Duration staleTmpThreshold = Duration(seconds: 60);

  bool _staleTmpSwept = false;

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
  ///
  /// Setiap instance menyapu orphan `.tmp` stale sekali pada panggilan
  /// pertama (bug-hunt-run128 BUG-3); kegagalan sweep best-effort senyap.
  Future<List<PendingDraftEntry>> pendingEntries() async {
    if (!await _dir.exists()) return const <PendingDraftEntry>[];
    await _sweepStaleTmpArtifactsOnce();
    final entries = <PendingDraftEntry>[];
    await for (final entity in _dir.list()) {
      if (entity is! File) continue;
      if (!entity.path.endsWith('.json')) continue;
      try {
        final decoded =
            jsonDecode(await entity.readAsString()) as Map<String, dynamic>;
        final sceneId = decoded['sceneId'] as String?;
        final content = decoded['content'] as String?;
        if (sceneId == null || sceneId.isEmpty || content == null) {
          // JSON valid tetapi field wajib tidak lengkap: tidak dapat
          // dipulihkan, tetapi tetap di-surface (BUG-1, no silent loss).
          entries.add(
            PendingDraftEntry.corrupt(
              sceneId: p.basenameWithoutExtension(entity.path),
            ),
          );
          continue;
        }
        entries.add(
          PendingDraftEntry(
            sceneId: sceneId,
            content: content,
            stagedAt: DateTime.tryParse(decoded['stagedAt'] as String? ?? ''),
          ),
        );
      } on FormatException {
        // File final terpotong/korup (crash/power-loss di jendela tulis):
        // SATU-SATUNYA salinan draf unsaved pengguna — jangan dibuang
        // diam-diam (bug-hunt-run128 BUG-1). Surface sebagai entri korup
        // agar panel DRAFT RECOVERY menampilkan statusnya. Artefak .tmp
        // in-progress tidak pernah mencapai sini (saringan .endsWith).
        entries.add(
          PendingDraftEntry.corrupt(
            sceneId: p.basenameWithoutExtension(entity.path),
          ),
        );
      }
    }
    entries.sort((a, b) => a.sceneId.compareTo(b.sceneId));
    return entries;
  }

  /// Menghapus entri journal SETELAH konten tersimpan durable.
  ///
  /// [content] non-null membuat penghapusan content-aware (bug-hunt-run128
  /// BUG-8): entri hanya dihapus jika konten di disk PERSIS versi yang
  /// baru saja tersimpan. Jika stage lebih baru sudah menimpa file saat
  /// save lama berjalan, entri itu dipertahankan (no silent loss).
  /// [content] null = hapus tanpa syarat — hanya untuk keputusan eksplisit
  /// pengguna (buang draf / replay restore), bukan jalur autosave.
  Future<void> acknowledge(String sceneId, {String? content}) async {
    final file = _entryFile(sceneId);
    if (!await file.exists()) return;
    if (content != null) {
      try {
        final decoded =
            jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        if (decoded['content'] != content) return;
      } on Object {
        // File tidak terbaca/korup: jangan hapus buta — pemulihan tetap
        // memakai jalur entri valid, dan file korup diabaikan pendingEntries.
        return;
      }
    }
    await file.delete();
  }

  Future<void> close() async {
    _closed = true;
  }

  /// Sweep `.json.tmp` stale sekali-di-instance (bug-hunt-run128 BUG-3).
  ///
  /// `.tmp` berumur >= [staleTmpThreshold] adalah orphan dari writer yang
  /// mati di jendela rename (crash/power-loss) — bukan sumber pemulihan
  /// dan tidak pernah dipulihkan ruangnya. Age-gate melindungi jendela
  /// tulis writer hidup (jendela normal = milidetik). Hanya file yang
  /// dihapus, per-file best-effort: kegagalan I/O tidak mengganggu
  /// pemulihan draf dan instance tidak mencoba lagi (asumsi single
  /// writer; percobaan ulang di panggilan `pendingEntries()` berikutnya
  /// milik instance baru, mis. setelah restart).
  Future<void> _sweepStaleTmpArtifactsOnce() async {
    if (_staleTmpSwept) return;
    _staleTmpSwept = true;
    final now = _clock();
    await for (final entity in _dir.list()) {
      if (entity is! File) continue;
      if (!entity.path.endsWith('.json.tmp')) continue;
      try {
        final stat = await entity.stat();
        if (now.difference(stat.modified) < staleTmpThreshold) continue;
        await entity.delete();
      } on Object {
        // Best-effort: satu file .tmp yang tidak bisa dihapus (permission,
        // race) tidak boleh mengganggu jalur baca pemulihan.
      }
    }
  }
}

/// Satu entri draf yang belum tersimpan; dibaca dari journal durable.
class PendingDraftEntry {
  /// Entri korup/truncated: konten tidak dapat dibaca. [sceneId] berasal
  /// dari nama file ketika isi tidak terdekode, agar panel pemulihan tetap
  /// dapat menampilkan keberadaannya (no silent loss, bug-hunt-run128 BUG-1).
  const PendingDraftEntry.corrupt({required this.sceneId})
    : content = '',
      isCorrupt = true,
      stagedAt = null;

  const PendingDraftEntry({
    required this.sceneId,
    required this.content,
    required this.stagedAt,
    this.isCorrupt = false,
  });

  final String sceneId;
  final String content;

  /// True ketika entri tidak dapat didekode (truncated/korup). Entri korup
  /// TIDAK dapat direstore ulang ke repository; ia ditampilkan agar pengguna
  /// tahu draf unsaved pernah ada dan bisa menghapusnya secara eksplisit.
  final bool isCorrupt;
  final DateTime? stagedAt;
}
