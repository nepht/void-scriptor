import 'package:vector_math/vector_math_64.dart';

class StageActor {
  StageActor({required this.id, required this.position});
  final String id;
  final Vector3 position;
}

class StageLight {
  StageLight({required this.id, required this.position});
  final String id;
  final Vector3 position;
}

/// Virtual stage with actor and light placement (Step 35.7–35.9).
class VirtualStage {
  final List<StageActor> _actors = [];
  final List<StageLight> _lights = [];

  List<StageActor> get actors => List.unmodifiable(_actors);
  List<StageLight> get lights => List.unmodifiable(_lights);

  void addActor(String id, Vector3 position) =>
      _actors.add(StageActor(id: id, position: position));

  void addLight(String id, Vector3 position) =>
      _lights.add(StageLight(id: id, position: position));

  List<StageActor> depthSortedActors() {
    final sorted = List<StageActor>.from(_actors);
    // Sort by z (depth): far (more negative z) first for back-to-front.
    sorted.sort((a, b) => a.position.z.compareTo(b.position.z));
    return sorted;
  }
}
