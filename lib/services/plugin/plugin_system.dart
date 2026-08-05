// Plugin System — v1.0.0
// Extensible plugin architecture for Void Scriptor.

abstract class VoidPlugin {
  final String name;
  final String version;
  final String description;

  VoidPlugin({
    required this.name,
    required this.version,
    required this.description,
  });

  Future<void> initialize();
  Future<void> dispose();
  Map<String, dynamic> getCapabilities();
}

class PluginRegistry {
  final List<VoidPlugin> _plugins = [];

  List<VoidPlugin> get plugins => List.unmodifiable(_plugins);

  void register(VoidPlugin plugin) {
    _plugins.add(plugin);
  }

  void unregister(String pluginName) {
    _plugins.removeWhere((p) => p.name == pluginName);
  }

  VoidPlugin? find(String name) {
    return _plugins.where((p) => p.name == name).firstOrNull;
  }
}

final pluginRegistry = PluginRegistry();
