// Kontrak Character Moodboard Workspace (Step 109.28) — RED pertama.
//
// Acceptance kanonik sprint_109.json: local_media, categories,
// annotations, source_credit, missing_file_state.
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/character/domain/character_moodboard.dart';

void main() {
  group('local_media', () {
    test('item media lokal tervalidasi dan terdaftar', () {
      final board = CharacterMoodboard(characterId: 'n-kael')
        ..addItem(
          const MoodboardItem(
            id: 'm-1',
            filePath: '/media/wajah-kael.png',
            category: 'wajah',
          ),
        );
      expect(board.items.single.filePath, '/media/wajah-kael.png');
      expect(
        () => board.addItem(
          const MoodboardItem(id: 'm-2', filePath: ' ', category: 'pakaian'),
        ),
        throwsArgumentError,
      );
      expect(
        () => board.addItem(
          const MoodboardItem(
            id: 'm-1',
            filePath: '/media/dup.png',
            category: 'prop',
          ),
        ),
        throwsStateError,
      );
    });
  });

  group('categories', () {
    test('kategori mengelompokkan item dan bisa difilter', () {
      final board = CharacterMoodboard(characterId: 'n-mira')
        ..addItem(
          const MoodboardItem(id: 'm-1', filePath: '/a.png', category: 'wajah'),
        )
        ..addItem(
          const MoodboardItem(
            id: 'm-2',
            filePath: '/b.png',
            category: 'pakaian',
          ),
        )
        ..addItem(
          const MoodboardItem(id: 'm-3', filePath: '/c.png', category: 'wajah'),
        );
      expect(board.categories, <String>['wajah', 'pakaian']);
      expect(board.itemsInCategory('wajah').map((i) => i.id).toList(), <String>[
        'm-1',
        'm-3',
      ]);
      expect(board.itemsInCategory('lingkungan'), isEmpty);
    });
  });

  group('annotations', () {
    test('anotasi kronologis jam-suntik per item', () {
      var tick = DateTime(2026, 8, 26, 15);
      final board =
          CharacterMoodboard(
            characterId: 'n-kael',
            clock: () {
              tick = tick.add(const Duration(minutes: 3));
              return tick;
            },
          )..addItem(
            const MoodboardItem(
              id: 'm-1',
              filePath: '/a.png',
              category: 'wajah',
            ),
          );
      board.annotate('m-1', 'luka bakar di pipi kiri, canon');
      board.annotate('m-1', 'pencahayaan senja dipakai di bab 12');
      final notes = board.annotationsOf('m-1');
      expect(notes.length, 2);
      expect(notes[0].text, contains('pipi kiri'));
      expect(notes[1].at.isAfter(notes[0].at), isTrue);
      expect(() => board.annotate('hantu', 'x'), throwsStateError);
    });
  });

  group('source_credit', () {
    test('kredit sumber tersimpan dan ikut roundtrip JSON', () {
      const item = MoodboardItem(
        id: 'm-1',
        filePath: '/a.png',
        category: 'pakaian',
        sourceCredit: 'sketsa @seniman, lisensi CC-BY',
      );
      final board = CharacterMoodboard(characterId: 'n-mira')..addItem(item);
      expect(board.items.single.sourceCredit, contains('CC-BY'));
      expect(MoodboardItem.fromJson(item.toJson()), item);
      // Item tanpa kredit tetap valid dan stabil.
      const bare = MoodboardItem(
        id: 'm-2',
        filePath: '/b.png',
        category: 'wajah',
      );
      expect(bare.sourceCredit, isNull);
      expect(MoodboardItem.fromJson(bare.toJson()), bare);
    });
  });

  group('missing_file_state', () {
    test('file hilang ditandai, dilaporkan, dan bisa pulih', () {
      final board = CharacterMoodboard(characterId: 'n-kael')
        ..addItem(
          const MoodboardItem(
            id: 'm-1',
            filePath: '/hilang.png',
            category: 'wajah',
          ),
        )
        ..addItem(
          const MoodboardItem(
            id: 'm-2',
            filePath: '/ada.png',
            category: 'prop',
          ),
        );
      board.markMissing('m-1');
      expect(board.missingItemIds, <String>['m-1']);
      expect(board.items.first.isMissing, isTrue);
      // Roundtrip mempertahankan state missing.
      final restored = MoodboardItem.fromJson(board.items.first.toJson());
      expect(restored.isMissing, isTrue);
      expect(() => board.markMissing('hantu'), throwsStateError);
      board.markPresent('m-1');
      expect(board.missingItemIds, isEmpty);
    });
  });
}
