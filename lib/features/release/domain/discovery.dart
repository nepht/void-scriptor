/// Sprint 49 — Step 49.44–49.51 Discovery, Search, Reviews.
class DiscoveryResult {
  const DiscoveryResult({
    required this.id,
    required this.projectId,
    required this.score,
  });

  final String id;
  final String projectId;
  final double score;
}

class DiscoveryQuery {
  const DiscoveryQuery({
    required this.id,
    this.query,
    this.followedOnly = false,
  });

  final String id;
  final String? query;
  final bool followedOnly;
}

class Review {
  const Review({
    required this.id,
    required this.projectId,
    required this.authorId,
    required this.rating,
    this.dimensions = const {},
  });

  final String id;
  final String projectId;
  final String authorId;
  final double rating;
  final Map<String, double> dimensions;

  bool get eligible => rating >= 0 && rating <= 5;
}
