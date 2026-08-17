/// Sprint 44 — Step 44.28 Credentials Vault.
class CredentialsVault {
  const CredentialsVault({
    required this.secretId,
    required this.ownerCreatorId,
    required this.provider,
    required this.encryptedKey,
    this.metadata = const {},
  });

  final String secretId;
  final String ownerCreatorId;
  final String provider;
  final String encryptedKey;
  final Map<String, String> metadata;
}

/// Step 44.27 Provider Adapter Interface.
abstract class ProviderAdapter {
  Future<Map<String, dynamic>> call(
    String provider,
    Map<String, dynamic> params,
  );
}

/// Step 44.30 Seller Center.
class SellerCenterDashboard {
  const SellerCenterDashboard({
    required this.creatorId,
    required this.activeProducts,
    required this.pendingReviews,
    required this.totalEarnings,
  });

  final String creatorId;
  final int activeProducts;
  final int pendingReviews;
  final double totalEarnings;
}

/// Step 44.31 Create Product Wizard.
class ProductDraft {
  const ProductDraft({
    required this.id,
    required this.creatorId,
    required this.type,
    this.title,
    this.description,
    this.price,
    this.category,
    this.assets = const [],
    this.tags = const [],
    this.state = ProductDraftState.draft,
  });

  final String id;
  final String creatorId;
  final String type;
  final String? title;
  final String? description;
  final double? price;
  final String? category;
  final List<String> assets;
  final List<String> tags;
  final ProductDraftState state;
}

enum ProductDraftState { draft, submitted, approved, rejected, published }
