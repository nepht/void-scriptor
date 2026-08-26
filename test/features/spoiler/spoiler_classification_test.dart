// Kontrak Spoiler Classification Model (Step 109.30) — RED pertama.
//
// Acceptance kanonik sprint_109.json: spoiler_levels, reveal_point,
// audience_policy, inheritance_rules, safe_default.
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/spoiler/domain/spoiler_classification.dart';

void main() {
  group('spoiler_levels', () {
    test('klasifikasi eksplisit menentukan level efektif', () {
      final registry = SpoilerRegistry()
        ..classify('i-utuh', SpoilerLevel.clean);
      expect(registry.effectiveLevel('i-utuh'), SpoilerLevel.clean);
      registry.classify('i-utuh', SpoilerLevel.mild);
      expect(registry.effectiveLevel('i-utuh'), SpoilerLevel.mild);
      expect(
        () => registry.isVisible(
          itemId: 'hantu',
          audience: 'publik',
          currentScene: 'sc-01',
        ),
        throwsStateError,
      );
    });
  });

  group('reveal_point', () {
    test('tersembunyi sebelum adegan reveal, tampak pada/di atasnya', () {
      final registry = SpoilerRegistry()
        ..classify('i-kematian', SpoilerLevel.major)
        ..setRevealPoint('i-kematian', 'sc-10')
        ..addAudience(const SpoilerAudience('editor', SpoilerLevel.major));
      expect(
        registry.isVisible(
          itemId: 'i-kematian',
          audience: 'editor',
          currentScene: 'sc-09',
        ),
        isFalse,
      );
      expect(
        registry.isVisible(
          itemId: 'i-kematian',
          audience: 'editor',
          currentScene: 'sc-10',
        ),
        isTrue,
      );
    });
  });

  group('audience_policy', () {
    test('matriks level vs audience menentukan visibilitas', () {
      final registry = SpoilerRegistry()
        ..addAudience(const SpoilerAudience('publik', SpoilerLevel.clean))
        ..addAudience(const SpoilerAudience('beta', SpoilerLevel.mild))
        ..addAudience(const SpoilerAudience('editor', SpoilerLevel.major))
        ..classify('a', SpoilerLevel.clean)
        ..classify('b', SpoilerLevel.mild)
        ..classify('c', SpoilerLevel.major);
      expect(
        registry.isVisible(
          itemId: 'a',
          audience: 'publik',
          currentScene: 'sc-01',
        ),
        isTrue,
      );
      expect(
        registry.isVisible(
          itemId: 'b',
          audience: 'publik',
          currentScene: 'sc-01',
        ),
        isFalse,
      );
      expect(
        registry.isVisible(
          itemId: 'b',
          audience: 'beta',
          currentScene: 'sc-01',
        ),
        isTrue,
      );
      expect(
        registry.isVisible(
          itemId: 'c',
          audience: 'beta',
          currentScene: 'sc-01',
        ),
        isFalse,
      );
      expect(
        registry.isVisible(
          itemId: 'c',
          audience: 'editor',
          currentScene: 'sc-01',
        ),
        isTrue,
      );
      expect(
        () => registry.addAudience(
          const SpoilerAudience('publik', SpoilerLevel.mild),
        ),
        throwsStateError,
      );
    });
  });

  group('inheritance_rules', () {
    test('anggota mewarisi level grup kecuali diklasifikasi eksplisit', () {
      final registry = SpoilerRegistry()
        ..createGroup('g-reveal-besar', SpoilerLevel.major)
        ..createGroup('g-teaser', SpoilerLevel.mild)
        ..assignToGroup('u-1', 'g-reveal-besar')
        ..assignToGroup('u-2', 'g-teaser');
      expect(registry.effectiveLevel('u-1'), SpoilerLevel.major);
      expect(registry.effectiveLevel('u-2'), SpoilerLevel.mild);
      // Klasifikasi eksplisit mengalahkan grup.
      registry.classify('u-2', SpoilerLevel.clean);
      expect(registry.effectiveLevel('u-2'), SpoilerLevel.clean);
      expect(
        () => registry.assignToGroup('u-9', 'g-tak-ada'),
        throwsStateError,
      );
    });
  });

  group('safe_default', () {
    test('data tak terklasifikasi dianggap major secara default', () {
      final registry = SpoilerRegistry()
        ..addAudience(const SpoilerAudience('beta', SpoilerLevel.mild))
        ..addAudience(const SpoilerAudience('editor', SpoilerLevel.major));
      expect(registry.effectiveLevel('x-baru'), SpoilerLevel.major);
      expect(
        registry.isVisible(
          itemId: 'x-baru',
          audience: 'beta',
          currentScene: 'sc-99',
        ),
        isFalse,
      );
      expect(
        registry.isVisible(
          itemId: 'x-baru',
          audience: 'editor',
          currentScene: 'sc-99',
        ),
        isTrue,
      );
    });
  });
}
