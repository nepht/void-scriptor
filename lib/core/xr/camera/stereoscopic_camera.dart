/// Stereoscopic camera (Step 41.2–41.3).
class StereoscopicCamera {
  const StereoscopicCamera({required this.ipd});

  /// Interpupillary distance in meters.
  final double ipd;

  double get leftEyeX => -ipd / 2;
  double get rightEyeX => ipd / 2;
}
