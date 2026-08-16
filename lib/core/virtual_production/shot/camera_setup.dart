import 'package:vector_math/vector_math_64.dart';

enum Framing { wide, medium, closeUp, overShoulder }

/// Camera setup for a shot (Step 35.2).
class CameraSetup {
  const CameraSetup({
    required this.position,
    required this.target,
    required this.fovRadians,
    this.framing = Framing.medium,
    this.lensMm = 35,
  });

  final Vector3 position;
  final Vector3 target;
  final double fovRadians;
  final Framing framing;
  final double lensMm;
}
