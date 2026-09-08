/// Kontrak Draft Snapshot Compare & Restore (Step 109.22).
///
/// Penyimpan snapshot draf sebagai domain murni (tanpa DB/UI).
/// Lima kemampuan kanonik sprint_109.json:
/// 1. **automatic_snapshot** — rekam otomatis naskah verbatim tanpa
///    menyentuh teks kini;
/// 2. **manual_snapshot** — rekam manual berlabel, urut kronologis;
/// 3. **diff_view** — perbandingan baris deterministik terhadap teks
///    kini (hapus/tambah/tetap);
/// 4. **restore_creates_backup** — memulihkan SELALU mencadangkan teks
///    kini lebih dulu; snapshot asli tetap dapat dipulihkan ulang;
/// 5. **retention_controls** — batas jumlah snapshot per draf memangkas
///    yang tertua, teks kini tak pernah tersentuh.
library;

/// Jenis snapshot.
enum DraftSnapshotKind {
  /// Rekam otomatis.
  auto,

  /// Rekam manual berlabel.
  manual,

  /// Cadangan teks kini yang dibuat otomatis saat restore.
  restoreBackup,
}

/// Satu snapshot draf; konten selalu verbatim.
class DraftSnapshot {
  const DraftSnapshot({
    required this.kind,
    required this.content,
    required this.at,
    required this.label,
  });

  final DraftSnapshotKind kind;
  final String content;
  final DateTime at;

  /// Label bebas (manual) atau penanda jenis (auto/backup).
  final String label;

  Map<String, Object?> toJson() => <String, Object?>{
    'kind': kind.name,
    'content': content,
    'at': at.toIso8601String(),
    'label': label,
  };
}

/// Hasil perbandingan baris antara snapshot dan teks kini.
class SnapshotDiff {
  const SnapshotDiff({
    required this.removedLines,
    required this.addedLines,
    required this.unchangedCount,
  });

  /// Baris yang ada di snapshot tapi hilang di teks kini (urut kemunculan).
  final List<String> removedLines;

  /// Baris baru di teks kini yang tak ada di snapshot (urut kemunculan).
  final List<String> addedLines;

  /// Jumlah baris yang sama persis di keduanya.
  final int unchangedCount;
}

class _DraftState {
  String current = '';
  bool hasCurrent = false;
  int retentionLimit = 0;
  final List<DraftSnapshot> snapshots = <DraftSnapshot>[];
}

/// Penyimpan snapshot per draf. Murni domain; persistensi DB/UI menyusul
/// di lapisan integrasi.
class DraftSnapshotStore {
  DraftSnapshotStore({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  final Map<String, _DraftState> _drafts = <String, _DraftState>{};

  _DraftState _stateFor(String draftId) =>
      _drafts.putIfAbsent(draftId, _DraftState.new);

  void _enforceRetention(_DraftState state) {
    final limit = state.retentionLimit;
    if (limit <= 0 || state.snapshots.length <= limit) return;
    final excess = state.snapshots.length - limit;
    state.snapshots.removeRange(0, excess);
  }

  /// Memperbarui teks kini sebuah draf.
  void updateCurrent(String draftId, String content) {
    if (content.isEmpty) {
      throw ArgumentError('current text must not be empty');
    }
    final state = _stateFor(draftId);
    state.current = content;
    state.hasCurrent = true;
  }

  /// Teks kini sebuah draf; null bila belum ada.
  String? currentOf(String draftId) {
    final state = _drafts[draftId];
    if (state == null || !state.hasCurrent) return null;
    return state.current;
  }

  /// Rekam snapshot otomatis dari teks kini; [StateError] bila belum ada
  /// teks kini.
  void captureAuto(String draftId) {
    final state = _requireCurrent(draftId);
    state.snapshots.add(
      DraftSnapshot(
        kind: DraftSnapshotKind.auto,
        content: state.current,
        at: _clock(),
        label: 'otomatis',
      ),
    );
    _enforceRetention(state);
  }

  /// Rekam snapshot manual berlabel; label wajib non-kosong.
  void captureManual(
    String draftId, {
    required String label,
    required String content,
  }) {
    if (label.trim().isEmpty) {
      throw ArgumentError('label must not be blank');
    }
    final state = _stateFor(draftId);
    state.snapshots.add(
      DraftSnapshot(
        kind: DraftSnapshotKind.manual,
        content: content,
        at: _clock(),
        label: label.trim(),
      ),
    );
    _enforceRetention(state);
  }

  /// Menetapkan batas retensi snapshot untuk satu draf; [ArgumentError]
  /// bila bukan bilangan positif.
  void setRetention(String draftId, {required int maxSnapshots}) {
    if (maxSnapshots <= 0) {
      throw ArgumentError('maxSnapshots must be positive');
    }
    _stateFor(draftId).retentionLimit = maxSnapshots;
  }

  /// Snapshot sebuah draf urut kronologis (tertua -> terbaru).
  List<DraftSnapshot> snapshotsOf(String draftId) =>
      List.unmodifiable(_drafts[draftId]?.snapshots ?? const <DraftSnapshot>[]);

  /// Perbandingan baris snapshot [index] terhadap teks kini; deterministik.
  ///
  /// Semantik multiset: setiap baris dihitung per kejadian, bukan sebagai
  /// keanggotaan set, sehingga penggantian salinan duplikat (mis. satu 'A'
  /// dihapus sementara satu 'B' ditambah) tidak pernah dilaporkan tanpa
  /// perubahan (bug-hunt-run128 BUG-9).
  SnapshotDiff diffWithCurrent(String draftId, {required int index}) {
    final state = _stateFor(draftId);
    final snapshotLines = state.snapshots[index].content.split('\n');
    final currentLines = state.current.split('\n');
    final currentCounts = <String, int>{};
    for (final line in currentLines) {
      currentCounts[line] = (currentCounts[line] ?? 0) + 1;
    }
    final snapshotCounts = <String, int>{};
    for (final line in snapshotLines) {
      snapshotCounts[line] = (snapshotCounts[line] ?? 0) + 1;
    }
    final removed = <String>[];
    for (final entry in snapshotCounts.entries) {
      final surplus = entry.value - (currentCounts[entry.key] ?? 0);
      for (var i = 0; i < surplus; i++) {
        removed.add(entry.key);
      }
    }
    final added = <String>[];
    for (final entry in currentCounts.entries) {
      final surplus = entry.value - (snapshotCounts[entry.key] ?? 0);
      for (var i = 0; i < surplus; i++) {
        added.add(entry.key);
      }
    }
    var unchanged = 0;
    for (final entry in snapshotCounts.entries) {
      final inCurrent = currentCounts[entry.key] ?? 0;
      unchanged += entry.value < inCurrent ? entry.value : inCurrent;
    }
    return SnapshotDiff(
      removedLines: removed,
      addedLines: added,
      unchangedCount: unchanged,
    );
  }

  /// Memulihkan teks kini ke snapshot [index]; SELALU mencadangkan teks
  /// kini sebelumnya sebagai snapshot restoreBackup (dikecualikan dari
  /// pemangkasan retensi pada saat itu). Snapshot asli tetap utuh.
  void restoreTo(String draftId, {required int index}) {
    final state = _requireCurrent(draftId);
    final target = state.snapshots[index];
    state.snapshots.add(
      DraftSnapshot(
        kind: DraftSnapshotKind.restoreBackup,
        content: state.current,
        at: _clock(),
        label: 'cadangan sebelum pulih',
      ),
    );
    state.current = target.content;
  }

  _DraftState _requireCurrent(String draftId) {
    final state = _stateFor(draftId);
    if (!state.hasCurrent) {
      throw StateError('no current draft for $draftId');
    }
    return state;
  }
}
