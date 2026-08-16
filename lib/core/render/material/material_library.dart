import 'material.dart';

/// Registry of materials by id (Step 32.11).
class MaterialLibrary {
  final Map<String, Material> _materials = {};

  void register(Material material) => _materials[material.id] = material;

  Material? lookup(String id) => _materials[id];
}
