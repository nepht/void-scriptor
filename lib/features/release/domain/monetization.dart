/// Sprint 49 — Step 49.59–49.62 Monetization Types, Revenue Dashboard.
enum MonetizationType { free, paid, freemium, subscription, donation }

class RevenueBreakdown {
  const RevenueBreakdown({
    required this.id,
    required this.projectId,
    this.sources = const {},
  });

  final String id;
  final String projectId;
  final Map<String, double> sources;

  double get total => sources.values.fold(0, (sum, v) => sum + v);
}

class RevenueDashboard {
  const RevenueDashboard({
    required this.id,
    required this.creatorId,
    required this.breakdowns,
  });

  final String id;
  final String creatorId;
  final List<RevenueBreakdown> breakdowns;

  double get grandTotal => breakdowns.fold(0, (sum, b) => sum + b.total);
}
