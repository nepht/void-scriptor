import 'transform3d.dart';

/// A node in the scene hierarchy (Step 32.1).
class SceneNode {
  SceneNode({required this.id, Transform3D? transform})
    : transform = transform ?? Transform3D();

  final String id;
  final Transform3D transform;
  final List<SceneNode> _children = [];
  SceneNode? parent;

  List<SceneNode> get children => List.unmodifiable(_children);

  void add(SceneNode child) {
    if (child.parent != null) {
      child.parent!.remove(child);
    }
    child.parent = this;
    _children.add(child);
  }

  void remove(SceneNode child) {
    if (_children.remove(child)) {
      child.parent = null;
    }
  }

  SceneNode? find(String id) {
    if (this.id == id) return this;
    for (final child in _children) {
      final found = child.find(id);
      if (found != null) return found;
    }
    return null;
  }
}
