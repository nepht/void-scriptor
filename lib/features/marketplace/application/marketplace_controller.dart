import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/marketplace_item.dart';
import '../domain/marketplace_product_detail.dart';

class MarketplaceState {
  const MarketplaceState({
    this.featuredItems = const [],
    this.userLibrary = const [],
    this.selectedProduct,
  });

  final List<MarketplaceItem> featuredItems;
  final List<MarketplaceItem> userLibrary;
  final MarketplaceProductDetail? selectedProduct;

  MarketplaceState copyWith({
    List<MarketplaceItem>? featuredItems,
    List<MarketplaceItem>? userLibrary,
    MarketplaceProductDetail? selectedProduct,
  }) {
    return MarketplaceState(
      featuredItems: featuredItems ?? this.featuredItems,
      userLibrary: userLibrary ?? this.userLibrary,
      selectedProduct: selectedProduct ?? this.selectedProduct,
    );
  }
}

class MarketplaceController extends Notifier<MarketplaceState> {
  @override
  MarketplaceState build() => const MarketplaceState();

  void selectProduct(MarketplaceProductDetail product) {
    state = state.copyWith(selectedProduct: product);
  }

  Future<void> loadFeaturedItems(List<MarketplaceItem> items) async {
    // Di dunia nyata, ini akan memuat dari repository.
    state = state.copyWith(featuredItems: items);
  }
}

final marketplaceProvider =
    NotifierProvider<MarketplaceController, MarketplaceState>(
      MarketplaceController.new,
    );
