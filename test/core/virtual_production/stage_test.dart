import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:void_scriptor/core/virtual_production/stage/virtual_stage.dart';

void main() {
  test('VirtualStage places actors and lights', () {
    final stage = VirtualStage();
    stage.addActor('actor1', Vector3(0, 0, 0));
    stage.addActor('actor2', Vector3(0, 0, -5));
    stage.addLight('light1', Vector3(5, 5, 5));
    expect(stage.actors, hasLength(2));
    expect(stage.lights, hasLength(1));
  });

  test('VirtualStage depth sorts actors', () {
    final stage = VirtualStage();
    stage.addActor('near', Vector3(0, 0, -1));
    stage.addActor('far', Vector3(0, 0, -10));
    final sorted = stage.depthSortedActors();
    expect(sorted.first.id, 'far');
    expect(sorted.last.id, 'near');
  });
}
