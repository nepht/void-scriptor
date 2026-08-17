import 'cinema_project.dart';

/// Sprint 48 — Step 48.10–48.14 Virtual Camera.
enum CameraMovement {
  static,
  pan,
  tilt,
  dolly,
  track,
  crane,
  zoom,
  handheld,
  orbit,
}

class VirtualCamera {
  const VirtualCamera({
    required this.id,
    required this.shotId,
    this.preset = CameraPreset.medium,
    this.movement = CameraMovement.static,
    this.fov = 50.0,
  });

  final String id;
  final String shotId;
  final CameraPreset preset;
  final CameraMovement movement;
  final double fov;
}

class CameraPath {
  const CameraPath({
    required this.id,
    required this.cameraId,
    required this.points,
  });

  final String id;
  final String cameraId;
  final List<CameraPathPoint> points;
}

class CameraPathPoint {
  const CameraPathPoint({
    required this.sequence,
    required this.x,
    required this.y,
    required this.z,
  });

  final int sequence;
  final double x;
  final double y;
  final double z;
}
