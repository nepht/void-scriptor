import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/creator/domain/creator_specialization.dart';

void main() {
  group('CreatorSpecialization', () {
    test('exposes all thirteen canonical categories', () {
      expect(CreatorSpecialization.values, hasLength(13));
      expect(
        CreatorSpecialization.values.map((e) => e.label),
        containsAll([
          'Character Artist',
          'Concept Artist',
          'Illustrator',
          'Writer',
          'Animator',
          'Filmmaker',
          'Game Creator',
          'Environment Artist',
          'VFX Artist',
          'Sound Designer',
          'AI Creator',
          'Developer',
          'Multi-disciplinary Creator',
        ]),
      );
    });

    test('parses from label case-insensitively', () {
      expect(
        CreatorSpecialization.fromLabel('writer'),
        CreatorSpecialization.writer,
      );
      expect(
        CreatorSpecialization.fromLabel('AI Creator'),
        CreatorSpecialization.aiCreator,
      );
    });

    test('unknown label falls back to multiDisciplinary', () {
      expect(
        CreatorSpecialization.fromLabel('unknown'),
        CreatorSpecialization.multiDisciplinary,
      );
    });
  });
}