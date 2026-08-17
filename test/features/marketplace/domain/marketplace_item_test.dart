import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/marketplace/domain/marketplace_item.dart';

void main() {
  group('MarketplaceItem', () {
    test('creates with required fields', () {
      const item = MarketplaceItem(
        id: 'm1',
        title: 'Qowner Character Pack',
        sellerId: 'creator-1',
        category: MarketplaceCategory.characterAssets,
        price: 9.99,
      );
      expect(item.title, 'Qowner Character Pack');
      expect(item.price, 9.99);
      expect(item.category, MarketplaceCategory.characterAssets);
      expect(item.itemType, MarketplaceItemType.product);
    });

    test('agent items carry capability manifest', () {
      const agent = MarketplaceItem(
        id: 'a1',
        title: 'Canon Checker Agent',
        sellerId: 'creator-2',
        category: MarketplaceCategory.aiAgents,
        price: 0.0,
        itemType: MarketplaceItemType.agent,
        agentCapabilities: {'canon-check', 'continuity-review'},
      );
      expect(agent.itemType, MarketplaceItemType.agent);
      expect(agent.agentCapabilities, {'canon-check', 'continuity-review'});
    });

    test('copyWith preserves fields', () {
      const item = MarketplaceItem(
        id: 'm1',
        title: 'Original',
        sellerId: 'c1',
        category: MarketplaceCategory.characterAssets,
        price: 5.0,
      );
      final updated = item.copyWith(price: 7.99, title: 'Updated');
      expect(updated.price, 7.99);
      expect(updated.title, 'Updated');
      expect(updated.id, 'm1');
    });
  });
}
