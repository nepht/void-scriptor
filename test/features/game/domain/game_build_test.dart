import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/game/domain/game_build.dart';
import 'package:void_scriptor/features/game/domain/debug.dart';
import 'package:void_scriptor/features/game/domain/game_bible.dart';

void main() {
  group('GameBuildConfig', () {
    test('holds build configuration', () {
      const config = GameBuildConfig(
        id: 'cfg1',
        projectId: 'g1',
        target: BuildTarget.windows,
        optimizationLevel: 'release',
      );
      expect(config.target, BuildTarget.windows);
      expect(config.optimizationLevel, 'release');
    });
  });

  group('GameBible', () {
    test('holds game bible entries', () {
      const bible = GameBible(
        id: 'gb1',
        projectId: 'g1',
        entries: [
          GameBibleEntry(
            id: 'e1',
            title: 'Combat Rules',
            content: 'Damage is reduced by defense.',
          ),
        ],
      );
      expect(bible.entries.first.title, 'Combat Rules');
    });
  });

  group('GameplayLock', () {
    test('holds gameplay locks', () {
      const lock = GameplayLock(
        id: 'l1',
        entityId: 'char1',
        feature: 'signature-move',
        locked: true,
      );
      expect(lock.feature, 'signature-move');
      expect(lock.locked, isTrue);
    });
  });

  group('CoreLoopStep', () {
    test('defines core gameplay loop', () {
      expect(CoreLoopStep.values.map((e) => e.name), [
        'explore',
        'encounter',
        'combat',
        'reward',
        'progress',
      ]);
    });
  });
}
