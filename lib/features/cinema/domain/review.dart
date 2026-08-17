/// Sprint 48 — Step 48.78–48.85 Delivery Profiles, Shot Versions, Reviews, Status.
class DeliveryProfile {
  const DeliveryProfile({
    required this.id,
    required this.name,
    required this.platform,
    required this.container,
  });

  final String id;
  final String name;
  final String platform;
  final String container;
}

class ShotVersion {
  const ShotVersion({
    required this.id,
    required this.shotId,
    required this.versionNumber,
    required this.renderPresetId,
  });

  final String id;
  final String shotId;
  final int versionNumber;
  final String renderPresetId;
}

class ReviewComment {
  const ReviewComment({
    required this.id,
    required this.shotId,
    required this.author,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String shotId;
  final String author;
  final String text;
  final DateTime createdAt;
}

enum ShotStatus {
  concept,
  storyboard,
  blocking,
  animating,
  lighting,
  rendering,
  review,
  approved,
  finalCut,
}

class ShotStatusEntry {
  const ShotStatusEntry({
    required this.id,
    required this.shotId,
    required this.status,
    required this.updatedAt,
  });

  final String id;
  final String shotId;
  final ShotStatus status;
  final DateTime updatedAt;
}
