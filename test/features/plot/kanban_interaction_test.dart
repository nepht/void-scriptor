// Kontrak Kanban Plot Interaction (Step 109.26) — RED pertama.
//
// Acceptance kanonik sprint_109.json: drag_reorder, keyboard_reorder,
// multi_select, undo, screen_reader_announcement.
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/plot/domain/plot_board.dart';
import 'package:void_scriptor/features/plot/domain/kanban_interaction.dart';

PlotBoard _board() {
  final board = PlotBoard(projectId: 'p');
  for (final id in <String>['a', 'b', 'c', 'd']) {
    board.addCard(
      PlotCard(id: id, title: 'Kartu $id', status: PlotCardStatus.idea),
    );
  }
  return board;
}

void main() {
  group('drag_reorder', () {
    test('drop kartu ke indeks memindahkan tepat satu posisi', () {
      final session = KanbanInteractionSession(board: _board());
      session.drag(cardId: 'c', dropIndex: 0);
      expect(session.board.cards.map((x) => x.id).toList(), <String>[
        'c',
        'a',
        'b',
        'd',
      ]);
      expect(
        () => session.drag(cardId: 'hantu', dropIndex: 0),
        throwsStateError,
      );
      expect(() => session.drag(cardId: 'a', dropIndex: 9), throwsRangeError);
    });
  });

  group('keyboard_reorder', () {
    test('geser kiri/kanan setara drag pada posisi tetangga', () {
      final session = KanbanInteractionSession(board: _board());
      session.nudge(cardId: 'c', forward: true);
      expect(session.board.cards.map((x) => x.id).toList(), <String>[
        'a',
        'b',
        'd',
        'c',
      ]);
      session.nudge(cardId: 'c', forward: false);
      expect(session.board.cards.map((x) => x.id).toList(), <String>[
        'a',
        'b',
        'c',
        'd',
      ]);
      // Ujung papan tidak bergerak dan tidak error.
      session.nudge(cardId: 'a', forward: false);
      expect(session.board.cards.first.id, 'a');
      expect(
        () => session.nudge(cardId: 'hantu', forward: true),
        throwsStateError,
      );
    });
  });

  group('multi_select', () {
    test('blok terpilih bergerak utuh menjaga urutan relatif', () {
      final session = KanbanInteractionSession(board: _board())
        ..select('a')
        ..select('b');
      expect(session.selectedIds, <String>['a', 'b']);
      session.moveSelectedTo(dropIndex: 3);
      expect(session.board.cards.map((x) => x.id).toList(), <String>[
        'c',
        'd',
        'a',
        'b',
      ]);
      session.clearSelection();
      expect(session.selectedIds, isEmpty);
      expect(() => session.select('hantu'), throwsStateError);
    });
  });

  group('undo', () {
    test('setiap mutasi dapat dibalik sekali secara LIFO', () {
      final session = KanbanInteractionSession(board: _board());
      session.drag(cardId: 'c', dropIndex: 0);
      session.select('d');
      session.moveSelectedTo(dropIndex: 2);
      expect(session.board.cards.map((x) => x.id).toList(), <String>[
        'c',
        'a',
        'd',
        'b',
      ]);
      session.undo();
      expect(session.board.cards.map((x) => x.id).toList(), <String>[
        'c',
        'a',
        'b',
        'd',
      ]);
      session.undo();
      expect(session.board.cards.map((x) => x.id).toList(), <String>[
        'a',
        'b',
        'c',
        'd',
      ]);
      expect(() => session.undo(), throwsStateError);
    });
  });

  group('screen_reader_announcement', () {
    test('setiap aksi menghasilkan pengumuman deterministik', () {
      final session = KanbanInteractionSession(board: _board());
      session.drag(cardId: 'c', dropIndex: 0);
      expect(session.announcements.last.message, contains('c'));
      session.nudge(cardId: 'b', forward: true);
      expect(session.announcements.last.message, isNot(contains('drag')));
      expect(session.announcements.last.message, contains('b'));
      session.select('d');
      expect(session.announcements.last.message, contains('d'));
      session.undo();
      expect(session.announcements.last.message, contains('urungkan'));
    });
  });
}
