import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/creator/domain/creator_skill.dart';

void main() {
  group('CreatorSkill', () {
    test('holds skill identity with experience', () {
      const skill = CreatorSkill(
        creatorId: 'c1',
        skillId: 'character_design',
        level: 3,
        experience: 150.0,
      );
      expect(skill.level, 3);
      expect(skill.experience, 150.0);
      expect(skill.verified, isFalse);
    });

    test('copyWith updates fields', () {
      const skill = CreatorSkill(
        creatorId: 'c1',
        skillId: 'writing',
        level: 1,
        experience: 0,
      );
      final updated = skill.copyWith(level: 4, verified: true);
      expect(updated.level, 4);
      expect(updated.verified, isTrue);
      expect(updated.skillId, 'writing');
    });
  });
}
