import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/marketplace/domain/marketplace_product_detail.dart';

void main() {
  group('MarketplaceProductDetail', () {
    test('holds full item + seller info + screenshots', () {
      const detail = MarketplaceProductDetail(
        itemId: 'p1',
        itemTitle: 'Character Concept Pack',
        description: 'High-quality character concept illustrations.',
        sellerDisplayName: 'Creator Studio',
        sellerRating: 4.8,
        screenshots: ['asset1', 'asset2'],
        version: '2.1.0',
        downloads: 450,
        tags: ['character', 'concept', '2d'],
        reviews: [],
      );
      expect(detail.itemTitle, 'Character Concept Pack');
      expect(detail.sellerRating, 4.8);
      expect(detail.screenshots, ['asset1', 'asset2']);
    });

    test('copyWith updates fields', () {
      const detail = MarketplaceProductDetail(
        itemId: 'p1',
        itemTitle: 'Old',
        sellerDisplayName: 'Seller',
        version: '1.0',
        downloads: 100,
      );
      final updated = detail.copyWith(
        version: '1.1',
        downloads: 120,
        tags: ['updated'],
      );
      expect(updated.version, '1.1');
      expect(updated.downloads, 120);
      expect(updated.tags, ['updated']);
    });
  });
}
