import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/xr/spatial/spatial_scene.dart';
import 'package:void_scriptor/core/xr/spatial/room_scale_transform.dart';

void main() {
  test('SpatialAnchor holds position and content', () {
    const anchor = SpatialAnchor(
      id: 'a1',
      x: 1.0,
      y: 0.0,
      z: -2.0,
      contentId: 'c1',
    );
    expect(anchor.contentId, 'c1');
    expect(anchor.z, -2.0);
  });

  test('SpatialScene adds and queries anchors', () {
    final scene = SpatialScene();
    scene.add(const SpatialAnchor(id: 'a1', x: 1, y: 0, z: 0, contentId: 'c1'));
    scene.add(const SpatialAnchor(id: 'a2', x: 2, y: 0, z: 0, contentId: 'c1'));
    expect(scene.anchorCount, 2);
    expect(scene.anchorsForContent('c1'), hasLength(2));
    expect(scene.anchorsForContent('missing'), isEmpty);
  });

  test('RoomScaleTransform bounds check', () {
    const room = RoomScaleTransform(
      originX: 0,
      originY: 0,
      originZ: 0,
      width: 2,
      height: 2,
      depth: 2,
    );
    expect(room.inBounds(1, 1, 1), isTrue);
    expect(room.inBounds(5, 5, 5), isFalse);
  });
}
