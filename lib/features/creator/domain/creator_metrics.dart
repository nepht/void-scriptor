/// Sprint 43 — Step 43.6 Dashboard Metrics.
///
/// Canonical creator dashboard metrics. Social statistics can be hidden for
/// private users, in which case the corresponding fields are null.
class CreatorMetrics {
  const CreatorMetrics({
    required this.activeProjects,
    required this.publishedWorks,
    required this.portfolioViews,
    this.followers,
    this.collaborations,
    this.assetSales,
    required this.aiUsage,
    required this.storageBytes,
  });

  /// Private/user metrics: no social stats.
  factory CreatorMetrics.private() => const CreatorMetrics(
    activeProjects: 0,
    publishedWorks: 0,
    portfolioViews: 0,
    aiUsage: 0,
    storageBytes: 0,
  );

  /// The eight canonical metric labels (order-stable).
  static const List<String> labels = [
    'Active Projects',
    'Published Works',
    'Portfolio Views',
    'Followers',
    'Collaborations',
    'Asset Sales',
    'AI Usage',
    'Storage',
  ];

  final int activeProjects;
  final int publishedWorks;
  final int portfolioViews;
  final int? followers;
  final int? collaborations;
  final int? assetSales;
  final int aiUsage;
  final int storageBytes;

  String get storageLabel {
    const kb = 1024;
    const mb = kb * 1024;
    const gb = mb * 1024;
    if (storageBytes >= gb) {
      return '${(storageBytes / gb).toStringAsFixed(1)} GB';
    }
    if (storageBytes >= mb) {
      return '${(storageBytes / mb).toStringAsFixed(1)} MB';
    }
    if (storageBytes >= kb) {
      return '${(storageBytes / kb).toStringAsFixed(1)} KB';
    }
    return '$storageBytes B';
  }

  CreatorMetrics copyWith({
    int? activeProjects,
    int? publishedWorks,
    int? portfolioViews,
    int? followers,
    int? collaborations,
    int? assetSales,
    int? aiUsage,
    int? storageBytes,
  }) {
    return CreatorMetrics(
      activeProjects: activeProjects ?? this.activeProjects,
      publishedWorks: publishedWorks ?? this.publishedWorks,
      portfolioViews: portfolioViews ?? this.portfolioViews,
      followers: followers ?? this.followers,
      collaborations: collaborations ?? this.collaborations,
      assetSales: assetSales ?? this.assetSales,
      aiUsage: aiUsage ?? this.aiUsage,
      storageBytes: storageBytes ?? this.storageBytes,
    );
  }
}
