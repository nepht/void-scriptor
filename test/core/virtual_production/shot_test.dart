import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/virtual_production/shot/shot.dart';
import 'package:void_scriptor/core/virtual_production/shot/camera_setup.dart';
import 'package:void_scriptor/core/virtual_production/shot/shot_list.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  test('Shot holds metadata', () {
    const shot = Shot(
      id: 's1',
      name: 'opening',
      startSeconds: 0,
      durationSeconds: 5,
      cameraId: 'cam1',
    );
    expect(shot.name, 'opening');
    expect(shot.durationSeconds, 5);
  });

  test('CameraSetup has framing and lens', () {
    final cam = CameraSetup(
      position: Vector3(0, 0, 10),
      target: Vector3(0, 0, 0),
      fovRadians: 1.0,
      framing: Framing.closeUp,
      lensMm: 50,
    );
    expect(cam.framing, Framing.closeUp);
    expect(cam.lensMm, 50);
  });

  test('ShotList adds and finds shots', () {
    final list = ShotList();
    list.add(
      const Shot(
        id: 's1',
        name: 'a',
        startSeconds: 0,
        durationSeconds: 2,
        cameraId: 'c',
      ),
    );
    list.add(
      const Shot(
        id: 's2',
        name: 'b',
        startSeconds: 2,
        durationSeconds: 3,
        cameraId: 'c',
      ),
    );
    expect(list.shots, hasLength(2));
    expect(list.find('s1')!.name, 'a');
    expect(list.totalDuration, 5);
  });
}
