// Kontrak Plot Order Synchronization (Step 109.27) — RED pertama.
//
// Acceptance kanonik sprint_109.json: explicit_sync, conflict_preview,
// dependency_warning, undo_sync, history.
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/plot/domain/plot_board.dart';
import 'package:void_scriptor/features/plot/domain/plot_order_sync.dart';

PlotBoard _board() {
  final board = PlotBoard(projectId: 'p')
    ..addCard(
      const PlotCard(
        id: 'k1',
        title: 'Buka',
        status: PlotCardStatus.drafting,
        chapterId: 'ch-1',
        sceneId: 'sc-a',
      ),
    )
    ..addCard(
      const PlotCard(
        id: 'k2',
        title: 'Tengah',
        status: PlotCardStatus.drafting,
        chapterId: 'ch-1',
        sceneId: 'sc-b',
      ),
    )
    ..addCard(
      const PlotCard(
        id: 'k3',
        title: 'Tutup',
        status: PlotCardStatus.done,
        chapterId: 'ch-2',
        sceneId: 'sc-c',
      ),
    );
  return board;
}

StoryOutline _outline() => StoryOutline(chapters: <String>['ch-1', 'ch-2'])
  ..setScenes('ch-1', <String>['sc-b', 'sc-a'])
  ..setScenes('ch-2', <String>['sc-c']);

void main() {
  group('explicit_sync', () {
    test('urutan cerita hanya berubah saat sinkron eksplisit', () {
      final outline = _outline();
      final synchronizer = PlotOrderSynchronizer(board: _board());
      expect(outline.scenesOf('ch-1'), <String>['sc-b', 'sc-a']);
      final result = synchronizer.syncTo(outline);
      expect(result.appliedChapters, <String>['ch-1', 'ch-2']);
      expect(outline.scenesOf('ch-1'), <String>['sc-a', 'sc-b']);
    });
  });

  group('conflict_preview', () {
    test('adegan yang hilang di salah satu sisi terpreview', () {
      final outline = _outline()..setScenes('ch-2', <String>[]);
      final synchronizer = PlotOrderSynchronizer(board: _board());
      final preview = synchronizer.previewConflicts(outline);
      expect(preview.missingInOutline, containsPair('ch-2', <String>['sc-c']));
      expect(preview.conflicts, isNotEmpty);
      // Papan tanpa konflik memberi preview kosong.
      final clean = PlotOrderSynchronizer(
        board: _board(),
      ).previewConflicts(_outline());
      expect(clean.conflicts, isEmpty);
    });
  });

  group('dependency_warning', () {
    test('kartu menunjuk bab tak dikenal memicu peringatan', () {
      final board = _board()
        ..addCard(
          const PlotCard(
            id: 'k4',
            title: 'Liar',
            status: PlotCardStatus.idea,
            chapterId: 'ch-hantu',
          ),
        );
      final synchronizer = PlotOrderSynchronizer(board: board);
      final warnings = synchronizer.dependencyWarnings(_outline());
      expect(warnings.map((w) => w.cardId), <String>['k4']);
      expect(warnings.single.message, contains('ch-hantu'));
    });
  });

  group('undo_sync', () {
    test('sinkron dapat dibalik sekali memulihkan urutan lama', () {
      final outline = _outline();
      final synchronizer = PlotOrderSynchronizer(board: _board());
      synchronizer.syncTo(outline);
      expect(outline.scenesOf('ch-1'), <String>['sc-a', 'sc-b']);
      synchronizer.undoSync();
      expect(outline.scenesOf('ch-1'), <String>['sc-b', 'sc-a']);
      expect(() => synchronizer.undoSync(), throwsStateError);
    });
  });

  group('history', () {
    test('riwayat sinkron kronologis dengan jam tersuntik', () {
      var tick = DateTime(2026, 8, 26, 14);
      final synchronizer = PlotOrderSynchronizer(
        board: _board(),
        clock: () {
          tick = tick.add(const Duration(minutes: 5));
          return tick;
        },
      )..syncTo(_outline());
      synchronizer.undoSync();
      synchronizer.syncTo(_outline());
      expect(synchronizer.history.length, 3);
      expect(synchronizer.history[0].kind, PlotSyncEventKind.sync);
      expect(synchronizer.history[1].kind, PlotSyncEventKind.undo);
      expect(synchronizer.history[2].kind, PlotSyncEventKind.sync);
      expect(
        synchronizer.history[0].at.isBefore(synchronizer.history[1].at),
        isTrue,
      );
    });
  });
}
