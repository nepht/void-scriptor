/// A single shot in the shot list (Step 35.1).
class Shot {
  const Shot({
    required this.id,
    required this.name,
    required this.startSeconds,
    required this.durationSeconds,
    required this.cameraId,
  });

  final String id;
  final String name;
  final double startSeconds;
  final double durationSeconds;
  final String cameraId;

  double get endSeconds => startSeconds + durationSeconds;
}
