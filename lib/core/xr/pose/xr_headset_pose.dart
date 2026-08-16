/// Headset pose (Step 41.1).
class XrHeadsetPose {
  const XrHeadsetPose({
    required this.x,
    required this.y,
    required this.z,
    required this.roll,
    required this.pitch,
    required this.yaw,
  });

  final double x;
  final double y;
  final double z;
  final double roll;
  final double pitch;
  final double yaw;
}
