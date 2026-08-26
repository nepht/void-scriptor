// Kontrak Plot Board Data Model (Step 109.25) — RED pertama.
//
// Outputs kanonik sprint_109.json: board_schema, card_schema,
// ordering_contract, story_sync_contract.
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/plot/domain/plot_board.dart';

void main() {
  group('board_schema', () {
    test('papan memuat kartu lengkap dengan semua dimensi cerita', () {
      final board = PlotBoard(projectId: 'p-void')
        ..addCard(
          const PlotCard(
            id: 'c-1',
            title: 'Kael menemusuri reruntuhan',
            status: PlotCardStatus.drafting,
            chapterId: 'ch-3',
            sceneId: 'sc-9',
            arcId: 'arc-kejatuhan',
            povCharacterId: 'n-kael',
            pacingLabel: 'lambat',
          ),
        );
      expect(board.projectId, 'p-void');
      expect(board.cards.single.title, 'Kael menemusuri reruntuhan');
      expect(board.cards.single.chapterId, 'ch-3');
      expect(
        () => board.addCard(
          const PlotCard(id: 'c-2', title: ' ', status: PlotCardStatus.idea),
        ),
        throwsArgumentError,
      );
      expect(
        () => board.addCard(
          const PlotCard(
            id: 'c-1',
            title: 'duplikat',
            status: PlotCardStatus.idea,
          ),
        ),
        throwsStateError,
      );
    });
  });

  group('card_schema', () {
    test('kartu roundtrip JSON deterministik', () {
      const card = PlotCard(
        id: 'c-1',
        title: 'Pertemuan di pelabuhan',
        status: PlotCardStatus.revision,
        chapterId: 'ch-4',
        sceneId: 'sc-2',
        arcId: 'arc-selatan',
        povCharacterId: 'n-mira',
        pacingLabel: 'cepat',
      );
      final json = card.toJson();
      expect(PlotCard.fromJson(json), card);
      expect(json['status'], 'revision');
      expect(json['pacingLabel'], 'cepat');
      // Kartu minimal tanpa tautan cerita juga valid.
      const bare = PlotCard(
        id: 'c-0',
        title: 'ide mentah',
        status: PlotCardStatus.idea,
      );
      expect(PlotCard.fromJson(bare.toJson()), bare);
    });
  });

  group('ordering_contract', () {
    test('urutan papan eksplisit dan reorder deterministik', () {
      final board = PlotBoard(projectId: 'p')
        ..addCard(
          const PlotCard(id: 'a', title: 'A', status: PlotCardStatus.idea),
        )
        ..addCard(
          const PlotCard(id: 'b', title: 'B', status: PlotCardStatus.idea),
        )
        ..addCard(
          const PlotCard(id: 'c', title: 'C', status: PlotCardStatus.idea),
        );
      expect(board.cards.map((x) => x.id).toList(), <String>['a', 'b', 'c']);
      board.moveCard('c', toIndex: 0);
      expect(board.cards.map((x) => x.id).toList(), <String>['c', 'a', 'b']);
      board.moveCard('c', toIndex: 2);
      expect(board.cards.map((x) => x.id).toList(), <String>['a', 'b', 'c']);
      expect(() => board.moveCard('a', toIndex: 5), throwsRangeError);
      expect(() => board.moveCard('hantu', toIndex: 0), throwsStateError);
    });
  });

  group('story_sync_contract', () {
    test('proyeksi sinkron dikelompokkan per bab dengan urutan kartu', () {
      final board = PlotBoard(projectId: 'p')
        ..addCard(
          const PlotCard(
            id: 's1',
            title: 'Buka bab 1',
            status: PlotCardStatus.drafting,
            chapterId: 'ch-1',
            sceneId: 'sc-1',
          ),
        )
        ..addCard(
          const PlotCard(
            id: 's2',
            title: 'Tutup bab 1',
            status: PlotCardStatus.drafting,
            chapterId: 'ch-1',
            sceneId: 'sc-2',
          ),
        )
        ..addCard(
          const PlotCard(
            id: 's3',
            title: 'Bab 2 tunggal',
            status: PlotCardStatus.done,
            chapterId: 'ch-2',
          ),
        )
        // Kartu tanpa bab tidak ikut proyeksi sinkron.
        ..addCard(
          const PlotCard(
            id: 'pool',
            title: 'kolam ide',
            status: PlotCardStatus.idea,
          ),
        );
      final projection = board.storySyncProjection();
      expect(projection.unlinkedCardIds, <String>['pool']);
      expect(projection.chapters.map((c) => c.chapterId).toList(), <String>[
        'ch-1',
        'ch-2',
      ]);
      expect(projection.chapters.first.sceneIds, <String>['sc-1', 'sc-2']);
      expect(projection.chapters.last.sceneIds, isEmpty);
    });
  });
}
