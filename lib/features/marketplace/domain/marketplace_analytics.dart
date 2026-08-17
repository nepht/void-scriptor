import 'marketplace_item.dart';

/// Sprint 44 — Analytics Steps (44.45–44.52).
class MarketplaceAnalytics {
  const MarketplaceAnalytics({
    required this.productId,
    required this.views,
    required this.downloads,
    required this.purchases,
    required this.conversionRate,
    this.reviews = const [],
  });

  final String productId;
  final int views;
  final int downloads;
  final int purchases;
  final double conversionRate;
  final List<AnalyticsReview> reviews;
}

class AnalyticsReview {
  const AnalyticsReview({
    required this.rating,
    required this.timestamp,
    this.comment,
  });

  final double rating;
  final DateTime timestamp;
  final String? comment;
}

/// Step 44.53–44.60 (Recommendation Engine).
class ProductRecommendation {
  const ProductRecommendation({
    required this.productId,
    required this.score,
    required this.reason,
  });

  final String productId;
  final double score;
  final String reason;
}

/// Step 44.61–44.70 (Notification System).
enum MarketplaceNotificationType {
  newProduct,
  purchase,
  review,
  payout,
  trialExpiring,
}

class MarketplaceNotification {
  const MarketplaceNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.read = false,
    this.actionUrl,
  });

  final String id;
  final MarketplaceNotificationType type;
  final String title;
  final String body;
  final bool read;
  final String? actionUrl;
}

/// Step 44.71–44.84 (Search, Filter, Discovery).
class MarketplaceSearchQuery {
  const MarketplaceSearchQuery({
    required this.query,
    this.category,
    this.minPrice,
    this.maxPrice,
    this.tags = const [],
  });

  final String query;
  final String? category;
  final double? minPrice;
  final double? maxPrice;
  final List<String> tags;
}

class SearchResult {
  const SearchResult({required this.item, required this.score});

  final MarketplaceItem item;
  final double score;
}
