import 'scene_node.dart';

/// Scene graph with pre-order traversal (Step 32.3).
class SceneGraph {
  SceneNode? root;

  List<SceneNode> traverse() {
    final result = <SceneNode>[];
    final r = root;
    if (r == null) return result;
    _visit(r, result);
    return result;
  }

  void _visit(SceneNode node, List<SceneNode> out) {
    out.add(node);
    for (final child in node.children) {
      _visit(child, out);
    }
  }
}
