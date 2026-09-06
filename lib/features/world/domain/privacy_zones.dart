enum PrivacySensitivity { public, restricted }

class PrivacyZone {
  const PrivacyZone({
    required this.id,
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
    required this.sensitivity,
  });

  final String id;
  final double minX;
  final double maxX;
  final double minY;
  final double maxY;
  final PrivacySensitivity sensitivity;

  bool get isValid => id.trim().isNotEmpty && maxX >= minX && maxY >= minY;

  bool contains(double x, double y) =>
      isValid && x >= minX && x <= maxX && y >= minY && y <= maxY;

  bool allowsCaptureAt(double x, double y) =>
      !contains(x, y) || sensitivity == PrivacySensitivity.public;
}

class PrivacyPolicy {
  const PrivacyPolicy({required this.zones});

  final List<PrivacyZone> zones;

  bool allowsCaptureAt(double x, double y) =>
      zones.every((zone) => zone.allowsCaptureAt(x, y));
}
