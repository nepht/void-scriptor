// Kontrak Visual Description Continuity (Step 109.29) — RED pertama.
//
// Acceptance kanonik sprint_109.json: attribute_registry,
// scene_comparison, explain_warning, timeline_awareness, user_override.
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/character/domain/visual_continuity.dart';

VisualCanon _canon() => VisualCanon()
  ..setAttribute('n-kael', 'mata', 'keperakan')
  ..setAttribute('n-kael', 'rambut', 'hitam panjang')
  ..setAttribute('n-mira', 'mata', 'cokelat hangat');

void main() {
  group('attribute_registry', () {
    test('atribut canon terdaftar per tokoh dan bisa dibaca', () {
      final canon = _canon();
      expect(canon.attributeOf('n-kael', 'mata'), 'keperakan');
      expect(canon.attributeOf('n-kael', 'bekas luka'), isNull);
      expect(
        () => canon.setAttribute('n-kael', 'mata', 'biru'),
        throwsStateError,
      );
    });
  });

  group('scene_comparison', () {
    test('deskripsi adegan dibandingkan dengan canon', () {
      final canon = _canon();
      final checker = VisualContinuityChecker(canon: canon);
      final report = checker.compare(
        characterId: 'n-kael',
        sceneId: 'sc-12',
        descriptions: const <String>[
          'matanya keperakan',
          'rambut hitam panjang',
        ],
      );
      expect(report.matches, containsPair('mata', 'keperakan'));
      expect(report.mismatches, isEmpty);
    });
  });

  group('explain_warning', () {
    test('mismatch diberi penjelasan deterministik', () {
      final canon = _canon();
      final checker = VisualContinuityChecker(canon: canon);
      final report = checker.compare(
        characterId: 'n-kael',
        sceneId: 'sc-13',
        descriptions: const <String>['matanya biru laut'],
      );
      expect(report.mismatches.keys, <String>['mata']);
      expect(report.explanationFor('mata')!, contains('keperakan'));
      expect(report.explanationFor('rambut'), isNull);
    });
  });

  group('timeline_awareness', () {
    test('deskripsi cocok bila berada setelah titik ubah canon', () {
      final canon = _canon()
        ..addChangePoint(
          characterId: 'n-kael',
          attribute: 'rambut',
          afterScene: 'sc-20',
          value: 'putus pendek',
        );
      final checker = VisualContinuityChecker(canon: canon);
      final before = checker.compare(
        characterId: 'n-kael',
        sceneId: 'sc-15',
        descriptions: const <String>['rambut hitam panjang'],
      );
      expect(before.mismatches, isEmpty);
      final after = checker.compare(
        characterId: 'n-kael',
        sceneId: 'sc-25',
        descriptions: const <String>['rambut putus pendek'],
      );
      expect(after.mismatches, isEmpty);
    });
  });

  group('user_override', () {
    test('override pengguna mengalahkan aturan canon untuk satu adegan', () {
      final canon = _canon();
      final checker = VisualContinuityChecker(canon: canon)
        ..override(
          characterId: 'n-kael',
          sceneId: 'sc-30',
          attribute: 'mata',
          expectedValue: 'merah sementara',
        );
      final report = checker.compare(
        characterId: 'n-kael',
        sceneId: 'sc-30',
        descriptions: const <String>['matanya merah sementara'],
      );
      expect(report.mismatches, isEmpty);
      // Adegan lain tetap mengikuti canon.
      final other = checker.compare(
        characterId: 'n-kael',
        sceneId: 'sc-31',
        descriptions: const <String>['matanya merah sementara'],
      );
      expect(other.mismatches.containsKey('mata'), isTrue);
    });
  });
}
