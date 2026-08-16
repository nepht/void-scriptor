import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/xr/pose/xr_headset_pose.dart';
import 'package:void_scriptor/core/xr/camera/stereoscopic_camera.dart';

void main() {
  test('XrHeadsetPose holds position and orientation', () {
    const pose = XrHeadsetPose(
      x: 1.0,
      y: 2.0,
      z: 3.0,
      roll: 0.0,
      pitch: 0.5,
      yaw: -0.5,
    );
    expect(pose.x, 1.0);
    expect(pose.yaw, -0.5);
  });

  test('StereoscopicCamera holds eye offsets and IPD', () {
    const camera = StereoscopicCamera(ipd: 0.064);
    expect(camera.leftEyeX, closeTo(-0.032, 1e-9));
    expect(camera.rightEyeX, closeTo(0.032, 1e-9));
  });

  test('eye offset scales with IPD', () {
    const narrow = StereoscopicCamera(ipd: 0.050);
    expect(narrow.leftEyeX, closeTo(-0.025, 1e-9));
    expect(narrow.rightEyeX, closeTo(0.025, 1e-9));
  });
}
