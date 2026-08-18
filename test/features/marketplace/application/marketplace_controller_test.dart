import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/marketplace/application/marketplace_controller.dart';
import 'package:void_scriptor/features/marketplace/domain/marketplace_item.dart';
import 'package:void_scriptor/features/marketplace/domain/marketplace_product_detail.dart';

void main() {
  group('MarketplaceController', () {
    test('initial state is empty', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final state = container.read(marketplaceProvider);
      expect(state.featuredItems, isEmpty);
      expect(state.userLibrary, isEmpty);
      expect(state.selectedProduct, isNull);
    });

    test('selectProduct updates the selected product', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      const product = MarketplaceProductDetail(
        itemId: '1',
        itemTitle: 'Test Product',
        sellerDisplayName: 'Test Author',
        description: 'A product for testing.',
        version: '1.0.0',
        downloads: 100,
      );
      container.read(marketplaceProvider.notifier).selectProduct(product);
      expect(container.read(marketplaceProvider).selectedProduct, product);
    });

    test('loadFeaturedItems updates featured items', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      // Di dunia nyata, ini akan memanggil repository.
      // Di sini kita panggil metode di controller langsung.
      final items = [
        const MarketplaceItem(
          id: '1',
          title: 'Featured 1',
          sellerId: 'seller-1',
          category: MarketplaceCategory.characterAssets,
          price: 4.99,
          itemType: MarketplaceItemType.product,
        ),
      ];
      await container
          .read(marketplaceProvider.notifier)
          .loadFeaturedItems(items);
      expect(container.read(marketplaceProvider).featuredItems, isNotEmpty);
      expect(
        container.read(marketplaceProvider).featuredItems.first.title,
        'Featured 1',
      );
    });
  });
}
