/// Sprint 43 — Step 43.35 Creator Community, 43.36 Follow System, 43.37 Notification Preferences.
enum FollowTarget { creator, project, universe, character }

class NotificationPreference {
  const NotificationPreference({
    required this.targetId,
    this.newEpisode = true,
    this.newCharacter = true,
    this.majorUpdate = true,
    this.minorAssetChanges = false,
  });

  final String targetId;
  final bool newEpisode;
  final bool newCharacter;
  final bool majorUpdate;
  final bool minorAssetChanges;
}
