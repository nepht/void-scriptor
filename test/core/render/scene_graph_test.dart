import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:void_scriptor/core/render/scene/scene_node.dart';
import 'package:void_scriptor/core/render/scene/transform3d.dart';
import 'package:void_scriptor/core/render/scene/scene_graph.dart';

void main() {
  test('SceneNode builds hierarchy and finds children', () {
    final root = SceneNode(id: 'root');
    final child = SceneNode(id: 'child');
    final grandchild = SceneNode(id: 'grandchild');
    root.add(child);
    child.add(grandchild);

    expect(root.children, hasLength(1));
    expect(child.parent, same(root));
    expect(root.find('grandchild'), same(grandchild));
    expect(root.find('nope'), isNull);
  });

  test('SceneNode removal detaches child', () {
    final root = SceneNode(id: 'root');
    final child = SceneNode(id: 'child');
    root.add(child);
    root.remove(child);
    expect(child.parent, isNull);
    expect(root.children, isEmpty);
  });

  test('Transform3D composes position/rotation/scale', () {
    final t = Transform3D(position: Vector3(1, 2, 3));
    expect(t.position.x, 1);
    expect(t.position.y, 2);
    expect(t.position.z, 3);
    final m = t.matrix;
    // Translation column: matrix translation = (1,2,3)
    expect(m.storage[12], closeTo(1, 1e-6));
    expect(m.storage[13], closeTo(2, 1e-6));
    expect(m.storage[14], closeTo(3, 1e-6));
  });

  test('SceneGraph traverses pre-order', () {
    final graph = SceneGraph();
    final root = SceneNode(id: 'root');
    final a = SceneNode(id: 'a');
    final b = SceneNode(id: 'b');
    root.add(a);
    root.add(b);
    graph.root = root;

    final ids = graph.traverse().map((n) => n.id).toList();
    expect(ids, ['root', 'a', 'b']);
  });
}
