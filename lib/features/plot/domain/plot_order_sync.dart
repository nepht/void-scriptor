/// Kontrak Plot Order Synchronization (Step 109.27).
///
/// Sinkronisasi urutan papan ke garis besar cerita sebagai domain murni
/// (tanpa DB/UI), mengikat PlotBoard 109.25. Lima kemampuan kanonik
/// sprint_109.json:
/// 1. **explicit_sync** — urutan cerita hanya berubah lewat perintah
///    sinkron eksplisit;
/// 2. **conflict_preview** — konflik terpreview sebelum sinkron; tidak
///    ada konflik diam-diam;
/// 3. **dependency_warning** — kartu menunjuk bab tak dikenal diberi
///    peringatan;
/// 4. **undo_sync** — sinkron dapat dibalik sekali per perintah (LIFO);
/// 5. **history** — riwayat kronologis dengan jam tersuntik.
library;

import 'plot_board.dart';

/// Garis besar cerita: bab berurutan memuat adegan berurutan.
class StoryOutline {
  StoryOutline({required List<String> chapters})
    : _chapters = <String>[...chapters];

  final List<String> _chapters;
  final Map<String, List<String>> _scenes = <String, List<String>>{};

  /// Bab urut kanonik.
  List<String> get chapters => List.unmodifiable(_chapters);

  /// Adegan sebuah bab; kosong bila bab belum punya adegan.
  List<String> scenesOf(String chapterId) =>
      List.unmodifiable(_scenes[chapterId] ?? const <String>[]);

  /// Mengganti seluruh adegan satu bab.
  void setScenes(String chapterId, List<String> sceneIds) {
    _scenes[chapterId] = <String>[...sceneIds];
  }
}

/// Satu konflik preview: adegan ada di papan tapi hilang di outline.
class PlotSyncConflict {
  const PlotSyncConflict({required this.chapterId, required this.sceneId});

  final String chapterId;
  final String sceneId;

  @override
  String toString() => '$chapterId/$sceneId hilang di outline';
}

/// Hasil preview konflik per bab.
class PlotSyncConflictPreview {
  const PlotSyncConflictPreview({
    required this.conflicts,
    required this.missingInOutline,
  });

  /// Seluruh konflik (urut bab kemunculan).
  final List<PlotSyncConflict> conflicts;

  /// Peta bab -> daftar adegan yang hilang di outline.
  final Map<String, List<String>> missingInOutline;
}

/// Peringatan ketergantungan untuk kartu bermasalah.
class PlotDependencyWarning {
  const PlotDependencyWarning({required this.cardId, required this.message});

  final String cardId;
  final String message;
}

/// Jenis kejadian riwayat sinkron.
enum PlotSyncEventKind {
  /// Perintah sinkron.
  sync,

  /// Pembalikan sinkron.
  undo,
}

/// Satu kejadian riwayat.
class PlotSyncEvent {
  const PlotSyncEvent({required this.kind, required this.at});

  final PlotSyncEventKind kind;
  final DateTime at;
}

/// Hasil satu perintah sinkron eksplisit.
class PlotSyncResult {
  const PlotSyncResult({required this.appliedChapters});

  /// Bab yang urutan adegannya ditulis ulang.
  final List<String> appliedChapters;
}

/// Snapshot mendalam satu outline untuk pembalikan.
class _OutlineSnapshot {
  _OutlineSnapshot._(this.chapters, this.scenes);

  factory _OutlineSnapshot.of(StoryOutline outline) => _OutlineSnapshot._(
    <String>[...outline.chapters],
    <String, List<String>>{
      for (final chapter in outline.chapters)
        chapter: <String>[...outline.scenesOf(chapter)],
    },
  );

  final List<String> chapters;
  final Map<String, List<String>> scenes;

  void restoreTo(StoryOutline outline) {
    for (final chapter in chapters) {
      outline.setScenes(chapter, scenes[chapter] ?? const <String>[]);
    }
  }
}

/// Penyinkron urutan papan -> outline; murni domain.
class PlotOrderSynchronizer {
  PlotOrderSynchronizer({required this.board, DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  /// Papan sumber perubahan urutan.
  final PlotBoard board;

  final DateTime Function() _clock;
  final List<PlotSyncEvent> _events = <PlotSyncEvent>[];
  final List<(_OutlineSnapshot, StoryOutline)> _undoStack =
      <(_OutlineSnapshot, StoryOutline)>[];

  /// Riwayat kejadian kronologis.
  List<PlotSyncEvent> get history => List.unmodifiable(_events);

  /// Preview konflik tanpa mengubah apa pun: adegan yang ada di papan
  /// tapi hilang dari outline dilaporkan per bab.
  PlotSyncConflictPreview previewConflicts(StoryOutline outline) {
    final boardScenes = <String, Set<String>>{};
    for (final card in board.cards) {
      final chapterId = card.chapterId;
      final sceneId = card.sceneId;
      if (chapterId == null || sceneId == null) continue;
      if (!outline.chapters.contains(chapterId)) continue;
      boardScenes.putIfAbsent(chapterId, () => <String>{}).add(sceneId);
    }
    final conflicts = <PlotSyncConflict>[];
    final missingInOutline = <String, List<String>>{};
    for (final chapter in outline.chapters) {
      final onBoard = boardScenes[chapter] ?? const <String>{};
      final inOutline = outline.scenesOf(chapter).toSet();
      final missing = onBoard.difference(inOutline).toList();
      if (missing.isNotEmpty) {
        missingInOutline[chapter] = missing;
        for (final sceneId in missing) {
          conflicts.add(PlotSyncConflict(chapterId: chapter, sceneId: sceneId));
        }
      }
    }
    return PlotSyncConflictPreview(
      conflicts: List.unmodifiable(conflicts),
      missingInOutline: Map.unmodifiable(missingInOutline),
    );
  }

  /// Peringatan ketergantungan: kartu yang menunjuk bab di luar outline.
  List<PlotDependencyWarning> dependencyWarnings(StoryOutline outline) {
    final warnings = <PlotDependencyWarning>[];
    final knownChapters = outline.chapters.toSet();
    for (final card in board.cards) {
      final chapterId = card.chapterId;
      if (chapterId != null && !knownChapters.contains(chapterId)) {
        warnings.add(
          PlotDependencyWarning(
            cardId: card.id,
            message: 'Kartu ${card.id} menunjuk bab tak dikenal $chapterId.',
          ),
        );
      }
    }
    return warnings;
  }

  /// Menulis ulang urutan adegan tiap bab outline mengikuti urutan
  /// papan; snapshot lama disimpan untuk pembalikan LIFO.
  PlotSyncResult syncTo(StoryOutline outline) {
    _undoStack.add((_OutlineSnapshot.of(outline), outline));
    final applied = <String>[];
    for (final chapter in outline.chapters) {
      final ordered = <String>[
        for (final card in board.cards)
          if (card.chapterId == chapter && card.sceneId != null) card.sceneId!,
      ];
      outline.setScenes(chapter, ordered);
      applied.add(chapter);
    }
    _events.add(PlotSyncEvent(kind: PlotSyncEventKind.sync, at: _clock()));
    return PlotSyncResult(appliedChapters: applied);
  }

  /// Membalik sinkron terakhir secara LIFO; [StateError] bila tidak
  /// ada sinkron yang dapat dibalik.
  void undoSync() {
    if (_undoStack.isEmpty) {
      throw StateError('nothing to undo');
    }
    final (snapshot, outline) = _undoStack.removeLast();
    snapshot.restoreTo(outline);
    _events.add(PlotSyncEvent(kind: PlotSyncEventKind.undo, at: _clock()));
  }
}
