import 'dart:async';

import '../../project_resilience/application/durable_draft_journal.dart';

/// Koordinator autosave yang menyatukan debounce, journal durable, dan
/// persist (Step 145.30 autosave snapshot and crash recovery).
///
/// Menggantikan blok inline `DebouncedAutosave + DurableDraftJournal` yang
/// sebelumnya tersebar di `StoryWorkspaceScreen` dengan satu koordinator
/// tunggal yang menjamin urutan no-silent-loss:
///
/// 1. Setiap perubahan draf langsung di-stage ke journal durable (crash
///    sebelum autosave tidak pernah kehilangan suntingan);
/// 2. Setelah debounce, konten di-persist ke repository;
/// 3. Entri journal di-acknowledge hanya SETELAH persist sukses;
/// 4. `dispose()` mem-flush draf yang masih menunggu debounce alih-alih
///    membuangnya (perbaikan terhadap `DebouncedAutosave.dispose()` yang
///    hanya membatalkan timer).
class DurableAutosaveCoordinator {
  DurableAutosaveCoordinator({
    this.debounceDelay = const Duration(milliseconds: 1500),
    required this._persist,
    this._journal,
    this.onSaved,
    this.onSaveStarted,
    this.onPersistError,
  });

  final Duration debounceDelay;
  final Future<void> Function(String sceneId, String content) _persist;
  final DurableDraftJournal? _journal;

  /// Dipanggil saat persist autosave GAGAL (debounce maupun flush dispose).
  /// Kontrak no-silent-loss: draf tetap pending dan entri journal durable
  /// tidak di-acknowledge sehingga konten terbaru tidak pernah hilang;
  /// lapisan UI memakai callback ini untuk menampilkan status gagal yang
  /// terlihat dan menyediakan retry eksplisit. Koordinator TIDAK melakukan
  /// retry otomatis tanpa batas: retry terjadi saat draf baru disunting
  /// atau lewat pemanggilan [saveNow] berikutnya.
  final void Function(String sceneId, String content, Object error)?
  onPersistError;

  /// Dipanggil SETELAH persist + acknowledge berhasil (bukan saat
  /// dijadwalkan). Dipakai layar untuk meng-update label "Tersimpan HH:MM".
  final void Function(String sceneId, String content)? onSaved;

  /// Dipanggil TEPAT SEBELUM persist autosave dimulai (save in-flight).
  /// Dipakai layar untuk menampilkan indikator 'Menyimpan...' sehingga
  /// jendela antara debounce selesai dan persist selesai terlihat oleh
  /// pengguna (friksi UX 145.43 #3: save-state indicator).
  final void Function(String sceneId, String content)? onSaveStarted;

  Timer? _timer;
  String? _pendingSceneId;
  String? _pendingContent;
  bool _saving = false;
  bool _retryRequested = false;

  Future<void> onDraftChanged({
    required String sceneId,
    required String content,
  }) async {
    // Journal durable terlebih dahulu: setelah Future ini selesai, entri
    // sudah tertulis atomic dan dijamin ada SEBELUM debounce autosave
    // dijadwalkan. Journal null (layar test tanpa paket) tidak masalah:
    // alur autosave utama tetap berjalan.
    //
    // bug-hunt-run128 BUG-2 (REAL BUG, Medium): dua kebocoran diperbaiki.
    // (1) Konten kosong (delete-all) adalah TRANSISI STATE, bukan error —
    //     tidak di-stage (kosong bukan draf yang perlu dipulihkan) sehingga
    //     ArgumentError journal tidak pernah terlempar di jalur terpanas.
    // (2) Kegagalan stage apa pun (disk penuh/permission) TIDAK boleh
    //     lolos uncaught dari rantai fire-and-forget layar: laporkan lewat
    //     onPersistError (penanganan kegagalan terlihat) dan lanjutkan
    //     penjadwalan autosave — persist tetap dicoba, draf tetap pending.
    if (content.trim().isNotEmpty) {
      try {
        await _journal?.stage(sceneId: sceneId, content: content);
      } catch (error) {
        onPersistError?.call(sceneId, content, error);
      }
    }
    _pendingSceneId = sceneId;
    _pendingContent = content;
    _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    _timer = Timer(debounceDelay, () => saveNow());
  }

  /// Menyimpan segera (digunakan saat flush dispose dan sebelum close).
  ///
  /// Jika dipanggil saat sebuah save masih berjalan, draf terbaru tidak
  /// dibuang: save yang berjalan diselesaikan dulu, lalu retry dijadwalkan
  /// untuk draf yang tertunda sehingga tidak ada suntingan yang hilang.
  Future<void> saveNow() async {
    _timer?.cancel();
    if (_saving) {
      _retryRequested = true;
      return;
    }
    final savedSceneId = _pendingSceneId;
    final savedContent = _pendingContent;
    if (savedSceneId == null || savedContent == null) return;
    _saving = true;
    onSaveStarted?.call(savedSceneId, savedContent);
    try {
      try {
        await _persist(savedSceneId, savedContent);
        // Acknowledge content-aware (bug-hunt-run128 BUG-8): entri journal
        // hanya dihapus jika masih memuat persis konten yang tersimpan.
        // Stage lebih baru (diketik saat save berjalan) mempertahankan
        // entrinya sehingga tidak ada staging yang hilang diam-diam.
        //
        // Pengecualian BUG-2: konten kosong yang BARU SAJA tersimpan
        // durable adalah keputusan pengguna (delete-all) — entri journal
        // lama dari teks sebelum delete-all tidak boleh tetap dipulihkan
        // (menghidupkan kembali teks yang sudah dihapus). Acknowledge
        // unconditional hanya untuk transisi kosong tersimpan ini.
        if (savedContent.trim().isEmpty) {
          await _journal?.acknowledge(savedSceneId);
        } else {
          await _journal?.acknowledge(savedSceneId, content: savedContent);
        }
        onSaved?.call(savedSceneId, savedContent);
        // Clear hanya jika scene DAN konten masih persis yang tersimpan —
        // draf baru yang di-set oleh onDraftChanged saat save berjalan
        // TIDAK dihapus (no silent loss); timer debounce berikutnya yang
        // menyimpannya.
        if (_pendingSceneId == savedSceneId &&
            _pendingContent == savedContent) {
          _pendingSceneId = null;
          _pendingContent = null;
        }
      } catch (error) {
        // Kegagalan persist tidak boleh silent: laporkan ke lapisan UI,
        // pertahankan draf pending + entri journal (dapat di-retry atau
        // dipulihkan dari journal durable), lalu selesai tanpa melempar
        // ulang agar flush dispose tidak menjadi uncaught async error.
        onPersistError?.call(savedSceneId, savedContent, error);
      }
    } finally {
      _saving = false;
      if (_retryRequested) {
        _retryRequested = false;
        if (_pendingSceneId != null) _schedule();
      }
    }
  }

  /// Membatalkan timer lalu mem-flush draf yang masih menunggu debounce.
  Future<void> dispose() async {
    _timer?.cancel();
    await saveNow();
  }
}
