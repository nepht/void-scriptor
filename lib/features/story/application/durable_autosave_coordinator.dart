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
    this.onAcknowledgeError,
  });

  /// Dipanggil saat persist SUKSES tetapi acknowledge jurnal atau callback
  /// [onSaved] gagal (vs-hunt-20260912-autosave BUG-17). Ini BUKAN
  /// [onPersistError]: penyimpanan DB sudah durable sehingga UI tidak boleh
  /// menampilkan klaim palsu "Gagal menyimpan draf".
  final void Function(String sceneId, String content, Object error)?
  onAcknowledgeError;

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

  /// Generasi perubahan terakhir (vs-hunt-20260912-autosave BUG-2): setiap
  /// panggilan [onDraftChanged] mengambil nomor ini SEBELUM await apa pun,
  /// dan hanya kegagalan dari generasi yang masih aktif yang dilaporkan ke
  /// [onPersistError]. Tanpa guard, stage edit lama yang selesai belakangan
  /// (caller layar fire-and-forget) akan menimpa draf aktif dengan konten
  /// lama dan memunculkan banner error untuk teks yang sudah digantikan.
  int _changeGeneration = 0;

  /// Save terakhir yang sedang berjalan (BUG-3): [dispose] menunggu
  /// saveNode ini tuntas alih-alih hanya melempar _retryRequested yang
  /// kemudian mengarm Timer post-dispose.
  Future<void>? _inFlightSave;

  Future<void> onDraftChanged({
    required String sceneId,
    required String content,
  }) async {
    // Journal durable: konten terbaru dipasang ke state pending SEKETIKA
    // (sinkron, sebelum await apa pun) sehingga panggilan terakhir selalu
    // menang berapa pun urutan penyelesaian I/O stage — dan entri jurnal
    // tetap ditulis sebelum debounce dijadwalkan (kontrak 145.30: crash
    // sebelum autosave tidak pernah kehilangan suntingan; stage per-scene
    // ter-FIFO di jurnal untuk penulisan urut).
    //
    // bug-hunt-run128 BUG-2 (REAL BUG, Medium): dua kebocoran diperbaiki.
    // (1) Konten kosong (delete-all) adalah TRANSISI STATE, bukan error —
    //     tidak di-stage (kosong bukan draf yang perlu dipulihkan) sehingga
    //     ArgumentError journal tidak pernah terlempar di jalur terpanas.
    // (2) Kegagalan stage apa pun (disk penuh/permission) TIDAK boleh
    //     lolos uncaught dari rantai fire-and-forget layar: laporkan lewat
    //     onPersistError (penanganan kegagalan terlihat) dan lanjutkan
    //     penjadwalan autosave — persist tetap dicoba, draf tetap pending.
    //
    // vs-hunt-20260912-autosave BUG-2 (Critical): guard generasi membuat
    // aturan (2) presisi — error hanya untuk draf yang MASIH aktif.
    final generation = ++_changeGeneration;
    _pendingSceneId = sceneId;
    _pendingContent = content;
    if (content.trim().isNotEmpty) {
      try {
        await _journal?.stage(sceneId: sceneId, content: content);
      } catch (error) {
        if (generation == _changeGeneration &&
            _pendingSceneId == sceneId &&
            _pendingContent == content) {
          onPersistError?.call(sceneId, content, error);
        }
      }
    }
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
  /// [dispose] MENUNGGU save in-flight (vs-hunt-20260912-autosave BUG-3),
  /// jadi flush yang di-await selalu menyelesaikan konten terbaru.
  Future<void> saveNow() async {
    _timer?.cancel();
    if (_saving) {
      _retryRequested = true;
      await _inFlightSave;
      // Setelah save pertama tuntas, jalankan satu flush lagi untuk draf
      // yang baru saja digantikan — bukan sekadar mengarm timer (BUG-3:
      // pada jalur dispose, timer itu akan menyala SETELAH objek mati).
      if (_retryRequested) {
        _retryRequested = false;
        await saveNow();
      }
      return;
    }
    final savedSceneId = _pendingSceneId;
    final savedContent = _pendingContent;
    if (savedSceneId == null || savedContent == null) return;
    _saving = true;
    final saveNode = _runSave(savedSceneId, savedContent);
    _inFlightSave = saveNode;
    await saveNode;
    _inFlightSave = null;
  }

  Future<void> _runSave(String savedSceneId, String savedContent) async {
    onSaveStarted?.call(savedSceneId, savedContent);
    try {
      await _persist(savedSceneId, savedContent);
    } catch (error) {
      // Kegagalan persist tidak boleh silent: laporkan ke lapisan UI,
      // pertahankan draf pending + entri journal (dapat di-retry atau
      // dipulihkan dari journal durable), lalu selesai tanpa melempar
      // ulang agar flush dispose tidak menjadi uncaught async error.
      onPersistError?.call(savedSceneId, savedContent, error);
      _saving = false;
      _finishRetry();
      return;
    }
    // Persist SUKSES. Kesalahan acknowledge/callback bukan kegagalan
    // draf — jangan dilaporkan sebagai "Gagal menyimpan" (BUG-17:
    // UI-state menyimpang dari kebenaran storage). Acknowledge tetap
    // content-aware, entri baru dari stage paralel dipertahankan.
    try {
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
      //
      // vs-hunt-20260912-autosave BUG-4 (Medium): ack unconditional hanya
      // sah bila transisi kosong MASIH menjadi draf aktif setelah await
      // persist. Jika selama await pengguna mengetik teks baru untuk scene
      // sama (pending tergantikan), entri jurnal baru wajib dipertahankan —
      // autosave berikutnya yang menyimpan dan meng-ack-nya.
      if (savedContent.trim().isEmpty) {
        if (_pendingSceneId == savedSceneId &&
            _pendingContent == savedContent) {
          await _journal?.acknowledge(savedSceneId);
        }
        // Terkantikan: JANGAN hapus entri stage baru; ack content-aware
        // konten kosong pun tidak sah (disk memuat teks lain).
      } else {
        await _journal?.acknowledge(savedSceneId, content: savedContent);
      }
      onSaved?.call(savedSceneId, savedContent);
      // Clear hanya jika scene DAN konten masih persis yang tersimpan —
      // draf baru yang di-set oleh onDraftChanged saat save berjalan
      // TIDAK dihapus (no silent loss); timer debounce berikutnya yang
      // menyimpannya.
      if (_pendingSceneId == savedSceneId && _pendingContent == savedContent) {
        _pendingSceneId = null;
        _pendingContent = null;
      }
    } catch (error) {
      onAcknowledgeError?.call(savedSceneId, savedContent, error);
    } finally {
      _saving = false;
      _finishRetry();
    }
  }

  void _finishRetry() {
    if (_retryRequested && !_disposed && _pendingSceneId != null) {
      // BUG-3: jangan pernah mengarm timer pada koordinator yang sudah
      // disposed — flush dispose yang await saveNow() yang menangani draf
      // (flag _retryRequested sengaja TIDAK dikosongkan saat disposed agar
      // saveNow() yang menunggu di jalur dispose tetap melakukan flush).
      _retryRequested = false;
      _schedule();
    }
  }

  /// vs-hunt-20260912-autosave BUG-5 (Critical): tulis eksternal yang
  /// MENGGANTIKAN konten draft (snapshot restore) wajib berkoordinasi
  /// dengan autosave pending, jika tidak debounce berikutnya menimpa hasil
  /// restore secara diam-diam.
  ///
  /// Urutan: flush pending scene lebih dulu (teks user tersimpan dan menjadi
  /// bahan cadangan pra-restore di repository), baru jalankan [write].
  /// Bila flush GAGAL (persist error — pending masih terpasang), pending
  /// dibuang TANPA acknowledge jurnal: entri jurnal adalah satu-satunya
  /// salinan teks itu dan recovery panel tetap menawarkan restore.
  /// Suntingan BARU yang datang selama [write] berjalan tidak disentuh —
  /// itu intensi pengguna pasca-restore.
  Future<T> aroundExternalDraftWrite<T>(
    String sceneId,
    Future<T> Function() write,
  ) async {
    final flushedContent = _pendingSceneId == sceneId ? _pendingContent : null;
    if (flushedContent != null) {
      await saveNow();
    }
    final result = await write();
    if (flushedContent != null &&
        _pendingSceneId == sceneId &&
        _pendingContent == flushedContent) {
      // Flush gagal — pending basi terhadap hasil restore. Buang dari
      // autosave; JANGAN hapus entri jurnalnya (satu-satunya salinan).
      _changeGeneration++;
      _pendingSceneId = null;
      _pendingContent = null;
      _timer?.cancel();
    }
    return result;
  }

  bool _disposed = false;

  /// Membatalkan timer lalu mem-flush draf yang masih menunggu debounce.
  /// Setelah future ini selesai, TIDAK ada lagi save/timer dari instance
  /// ini (vs-hunt-20260912-autosave BUG-3).
  Future<void> dispose() async {
    _disposed = true;
    _timer?.cancel();
    // BUG-3: jika sebuah save sedang berjalan, tunggu ia tuntas lalu flush
    // draf yang digantikannya — saveNow() sendiri menangani rantai retry.
    while (true) {
      await saveNow();
      if (!_saving && _inFlightSave == null) break;
      await _inFlightSave;
    }
  }
}
