/// Sprint 44 — Step 44.6 Product Detail Page.
class MarketplaceProductDetail {
  const MarketplaceProductDetail({
    required this.itemId,
    required this.itemTitle,
    this.description,
    required this.sellerDisplayName,
    this.sellerRating = 0.0,
    this.screenshots = const [],
    required this.version,
    required this.downloads,
    this.tags = const [],
    this.reviews = const [],
  });

  final String itemId;
  final String itemTitle;
  final String? description;
  final String sellerDisplayName;
  final double sellerRating;
  final List<String> screenshots;
  final String version;
  final int downloads;
  final List<String> tags;
  final List<ProductReview> reviews;

  MarketplaceProductDetail copyWith({
    String? description,
    double? sellerRating,
    List<String>? screenshots,
    String? version,
    int? downloads,
    List<String>? tags,
    List<ProductReview>? reviews,
  }) {
    return MarketplaceProductDetail(
      itemId: itemId,
      itemTitle: itemTitle,
      description: description ?? this.description,
      sellerDisplayName: sellerDisplayName,
      sellerRating: sellerRating ?? this.sellerRating,
      screenshots: screenshots ?? this.screenshots,
      version: version ?? this.version,
      downloads: downloads ?? this.downloads,
      tags: tags ?? this.tags,
      reviews: reviews ?? this.reviews,
    );
  }
}

class ProductReview {
  const ProductReview({
    required this.reviewerName,
    required this.rating,
    this.comment,
  });

  final String reviewerName;
  final double rating;
  final String? comment;
}
