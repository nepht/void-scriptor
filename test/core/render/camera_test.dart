import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:void_scriptor/core/render/camera/camera.dart';

void main() {
  test('Camera exposes projection and view matrices', () {
    final camera = Camera(
      position: Vector3(0, 0, 5),
      target: Vector3(0, 0, 0),
      fovYRadians: 1.0,
      aspect: 16 / 9,
      near: 0.1,
      far: 100,
    );
    expect(camera.projectionMatrix, isA<Matrix4>());
    expect(camera.viewMatrix, isA<Matrix4>());
    // view * projection transforms world into clip space
    final clip = camera.viewProjectionMatrix;
    expect(clip, isA<Matrix4>());
  });

  test('project maps a world point to screen space', () {
    final camera = Camera(
      position: Vector3(0, 0, 5),
      target: Vector3(0, 0, 0),
      fovYRadians: 1.0,
      aspect: 16 / 9,
      near: 0.1,
      far: 100,
    );
    final screen = camera.project(Vector3(0, 0, 0), 1920, 1080);
    // Center of screen.
    expect(screen.x, closeTo(960, 1.0));
    expect(screen.y, closeTo(540, 1.0));
  });

  test('LOD level decreases with distance', () {
    expect(LodSelector.levelFor(distance: 1, radii: [10, 30, 60]), 0);
    expect(LodSelector.levelFor(distance: 20, radii: [10, 30, 60]), 1);
    expect(LodSelector.levelFor(distance: 50, radii: [10, 30, 60]), 2);
  });

  test('frustum cull rejects point behind camera', () {
    final camera = Camera(
      position: Vector3(0, 0, 5),
      target: Vector3(0, 0, 0),
      fovYRadians: 1.0,
      aspect: 16 / 9,
      near: 0.1,
      far: 100,
    );
    // Point behind the camera (z > 5 along view axis).
    expect(camera.isInsideFrustum(Vector3(0, 0, 50)), isFalse);
    expect(camera.isInsideFrustum(Vector3(0, 0, 0)), isTrue);
  });
}
