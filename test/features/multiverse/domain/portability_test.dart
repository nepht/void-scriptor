import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/multiverse/domain/portability.dart';

void main() {
  group('CharacterVariant', () {
    test('holds variant with lock state', () {
      const v = CharacterVariant(
        id: 'v1',
        characterId: 'char1',
        universeId: 'u1',
        variantName: 'Evil Counterpart',
        identityLocked: false,
      );
      expect(v.variantName, 'Evil Counterpart');
      expect(v.identityLocked, isFalse);
      expect(v.isCanonVariant, isFalse);
    });

    test('canon variant is identity locked', () {
      const v = CharacterVariant(
        id: 'v1',
        characterId: 'char1',
        universeId: 'u1',
        variantName: 'Prime',
        identityLocked: true,
      );
      expect(v.isCanonVariant, isTrue);
    });
  });

  group('PortMode', () {
    test('exposes port modes', () {
      expect(PortMode.values.map((e) => e.name), [
        'reference',
        'clone',
        'variant',
        'lockedIdentity',
      ]);
    });
  });

  group('AssetLink', () {
    test('links asset across universes', () {
      const link = AssetLink(
        id: 'l1',
        assetId: 'a1',
        sourceUniverseId: 'u1',
        targetUniverseId: 'u2',
      );
      expect(link.sourceUniverseId, 'u1');
      expect(link.targetUniverseId, 'u2');
    });
  });

  group('AssetSnapshot', () {
    test('captures asset state', () {
      final snap = AssetSnapshot(
        id: 's1',
        assetId: 'a1',
        universeId: 'u2',
        contentHash: 'abc123',
        capturedAt: DateTime.utc(2026, 1, 1),
      );
      expect(snap.contentHash, 'abc123');
      expect(snap.universeId, 'u2');
    });
  });
}
