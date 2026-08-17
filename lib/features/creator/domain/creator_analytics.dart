/// Sprint 43 — Step 43.38 Creator Analytics, 43.39 Project Analytics, 43.40 Revenue Analytics.
class CreatorAnalytics {
  const CreatorAnalytics({
    this.portfolioViews = 0,
    this.projectViews = 0,
    this.followers = 0,
    this.engagement = 0,
    this.assetDownloads = 0,
    this.sales = 0,
    this.support = 0,
    this.collaborations = 0,
  });

  final int portfolioViews;
  final int projectViews;
  final int followers;
  final int engagement;
  final int assetDownloads;
  final int sales;
  final int support;
  final int collaborations;
}

class ProjectAnalytics {
  const ProjectAnalytics({
    this.views = 0,
    this.watchTimeSeconds = 0,
    this.completion = 0,
    this.likes = 0,
    this.comments = 0,
    this.shares = 0,
    this.support = 0,
  });

  final int views;
  final int watchTimeSeconds;
  final int completion;
  final int likes;
  final int comments;
  final int shares;
  final int support;
}

enum RevenueCategory {
  donations,
  membership,
  assetSales,
  commission,
  marketplace,
}

class RevenueAnalytics {
  const RevenueAnalytics({
    this.grossRevenue = 0.0,
    this.platformFee = 0.0,
    this.providerFee = 0.0,
    this.refund = 0.0,
  });

  final double grossRevenue;
  final double platformFee;
  final double providerFee;
  final double refund;

  double get netRevenue => grossRevenue - platformFee - providerFee - refund;
}
