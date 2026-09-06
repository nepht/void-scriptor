// Sprint 78 -- Step 78.82 (BAGIAN LXXIV -- Animatic Track).
//
// The blueprint defines the canonical animatic track set as exactly five
// kinds, in this order:
//   Video Track
//   Dialogue Track
//   SFX Track
//   Music Track
//   Notes Track
//
// This test pins the canonical list and per-track display names so downstream
// animatic preview, editor and persistence layers can rely on a single source
// of truth.

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/cinema/domain/animatic_track.dart';

void main() {
  group('AnimaticTrackType (Step 78.82)', () {
    test('canonical list has exactly five kinds in blueprint order', () {
      expect(AnimaticTrackType.canonical, hasLength(5));
      expect(AnimaticTrackType.canonical.map((t) => t.label).toList(), <String>[
        'Video Track',
        'Dialogue Track',
        'SFX Track',
        'Music Track',
        'Notes Track',
      ]);
    });

    test('every kind exposes its blueprint display label', () {
      for (final kind in AnimaticTrackType.canonical) {
        expect(kind.label, isNotEmpty);
        expect(kind.label, endsWith('Track'));
      }
    });

    test('canonical list is immutable', () {
      expect(
        () => AnimaticTrackType.canonical.add(AnimaticTrackType.video),
        throwsUnsupportedError,
      );
    });
  });
}
