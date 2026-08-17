/// Sprint 43 — Step 43.41 Creator Privacy, 43.42 Project Privacy, 43.43 AI Data Permission, 43.44 Training Permission.
class CreatorPrivacy {
  const CreatorPrivacy({
    this.showPortfolio = true,
    this.showAnalytics = false,
    this.showRevenue = false,
    this.allowAiTraining = false,
    this.allowAiContextByDefault = false,
  });

  final bool showPortfolio;
  final bool showAnalytics;
  final bool showRevenue;
  final bool allowAiTraining;
  final bool allowAiContextByDefault;

  CreatorPrivacy copyWith({
    bool? showPortfolio,
    bool? showAnalytics,
    bool? showRevenue,
    bool? allowAiTraining,
    bool? allowAiContextByDefault,
  }) {
    return CreatorPrivacy(
      showPortfolio: showPortfolio ?? this.showPortfolio,
      showAnalytics: showAnalytics ?? this.showAnalytics,
      showRevenue: showRevenue ?? this.showRevenue,
      allowAiTraining: allowAiTraining ?? this.allowAiTraining,
      allowAiContextByDefault:
          allowAiContextByDefault ?? this.allowAiContextByDefault,
    );
  }
}

/// Sprint 43 — Step 43.45 Device Sync, 43.46 Device Session, 43.47 Offline Mode.
class DeviceSession {
  const DeviceSession({
    required this.sessionId,
    required this.deviceName,
    required this.lastActiveAt,
    this.isActive = true,
  });

  final String sessionId;
  final String deviceName;
  final DateTime lastActiveAt;
  final bool isActive;
}

class OfflineCreatorState {
  const OfflineCreatorState({
    required this.creatorId,
    this.lastSyncedAt,
    this.pendingChanges = 0,
  });

  final String creatorId;
  final DateTime? lastSyncedAt;
  final int pendingChanges;
}

/// Sprint 43 — Step 43.57 Feature Flags.
class CreatorFeatureFlags {
  const CreatorFeatureFlags({
    this.portfolioEnabled = false,
    this.aiStudioEnabled = false,
    this.fundingEnabled = false,
    this.communityEnabled = false,
    this.analyticsEnabled = false,
  });

  final bool portfolioEnabled;
  final bool aiStudioEnabled;
  final bool fundingEnabled;
  final bool communityEnabled;
  final bool analyticsEnabled;
}
