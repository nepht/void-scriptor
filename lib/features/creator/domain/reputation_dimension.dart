/// Sprint 43 — Step 43.28 Reputation 2.0.
///
/// Multi-dimensional reputation (not a plain star rating).
enum ReputationDimension {
  quality,
  reliability,
  collaboration,
  contribution,
  originality,
  communityTrust,
}

/// Aggregated reputation score across the six dimensions (0–5 each).
class ReputationScore {
  const ReputationScore({
    required this.quality,
    required this.reliability,
    required this.collaboration,
    required this.contribution,
    required this.originality,
    required this.communityTrust,
  });

  final double quality;
  final double reliability;
  final double collaboration;
  final double contribution;
  final double originality;
  final double communityTrust;

  double get average {
    final total =
        quality +
        reliability +
        collaboration +
        contribution +
        originality +
        communityTrust;
    return total / 6;
  }

  double valueOf(ReputationDimension dimension) => switch (dimension) {
    ReputationDimension.quality => quality,
    ReputationDimension.reliability => reliability,
    ReputationDimension.collaboration => collaboration,
    ReputationDimension.contribution => contribution,
    ReputationDimension.originality => originality,
    ReputationDimension.communityTrust => communityTrust,
  };
}

/// Sprint 43 — Step 43.29 Reputation Protection controls.
enum ReputationProtectionControl {
  antiSpam,
  antiFakeReview,
  antiReviewFarming,
  reportSystem,
  appealSystem,
}

/// Sprint 43 — Step 43.30 Creator Verification levels.
enum CreatorVerificationLevel {
  standardCreator,
  verifiedCreator,
  verifiedStudio,
  officialPartner,
}
