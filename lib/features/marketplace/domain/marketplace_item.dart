/// Sprint 44 — Step 44.3 Marketplace Categories, 44.4 Marketplace Item Model, 44.5 Item Types.
enum MarketplaceCategory {
  characterAssets,
  environmentAssets,
  animationPresets,
  vfxPresets,
  audioPresets,
  storyTemplates,
  worldbuildingPacks,
  aiAgents,
  aiWorkflows,
  promptPacks,
  plugins,
  themes,
  tutorials,
  commissionServices,
}

enum MarketplaceItemType {
  product,
  agent,
  workflow,
  promptPack,
  service,
  template,
}

class MarketplaceItem {
  const MarketplaceItem({
    required this.id,
    required this.title,
    required this.sellerId,
    required this.category,
    required this.price,
    this.itemType = MarketplaceItemType.product,
    this.description,
    this.assetIds = const [],
    this.tags = const [],
    this.agentCapabilities = const <String>{},
    this.rating = 0.0,
    this.downloadCount = 0,
  });

  final String id;
  final String title;
  final String sellerId;
  final MarketplaceCategory category;
  final double price;
  final MarketplaceItemType itemType;
  final String? description;
  final List<String> assetIds;
  final List<String> tags;
  final Set<String> agentCapabilities;
  final double rating;
  final int downloadCount;

  MarketplaceItem copyWith({
    String? title,
    String? description,
    double? price,
    double? rating,
    int? downloadCount,
    List<String>? assetIds,
    List<String>? tags,
    Set<String>? agentCapabilities,
  }) {
    return MarketplaceItem(
      id: id,
      title: title ?? this.title,
      sellerId: sellerId,
      category: category,
      itemType: itemType,
      price: price ?? this.price,
      description: description ?? this.description,
      assetIds: assetIds ?? this.assetIds,
      tags: tags ?? this.tags,
      agentCapabilities: agentCapabilities ?? this.agentCapabilities,
      rating: rating ?? this.rating,
      downloadCount: downloadCount ?? this.downloadCount,
    );
  }
}
