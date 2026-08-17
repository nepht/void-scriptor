import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/creator/domain/portfolio_entry.dart';

void main() {
  group('PortfolioEntry', () {
    test('creates with required fields', () {
      const entry = PortfolioEntry(
        id: 'p1',
        creatorId: 'c1',
        title: 'My Project',
        visibility: PortfolioVisibility.public,
      );
      expect(entry.title, 'My Project');
      expect(entry.visibility, PortfolioVisibility.public);
      expect(entry.assetIds, isEmpty);
      expect(entry.tags, isEmpty);
    });

    test('copyWith updates fields', () {
      const entry = PortfolioEntry(
        id: 'p1',
        creatorId: 'c1',
        title: 'Old',
        visibility: PortfolioVisibility.private,
      );
      final updated = entry.copyWith(
        title: 'New',
        description: 'Desc',
        tags: ['tag1'],
      );
      expect(updated.title, 'New');
      expect(updated.description, 'Desc');
      expect(updated.tags, ['tag1']);
      expect(updated.visibility, PortfolioVisibility.private);
    });

    test('toJson/fromJson roundtrip', () {
      const entry = PortfolioEntry(
        id: 'p1',
        creatorId: 'c1',
        title: 'Test',
        description: 'Desc',
        assetIds: ['a1', 'a2'],
        tags: ['flutter', 'design'],
        visibility: PortfolioVisibility.unlisted,
      );
      final restored = PortfolioEntry.fromJson(entry.toJson());
      expect(restored.id, entry.id);
      expect(restored.assetIds, entry.assetIds);
      expect(restored.visibility, PortfolioVisibility.unlisted);
    });
  });
}
