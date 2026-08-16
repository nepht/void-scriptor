import '../domain/plugin_manifest.dart';
import '../api/plugin.dart';
import 'plugin_host.dart';

/// Registry of installed plugins with enable/disable lifecycle (Step 31.9).
class PluginRegistry {
  PluginRegistry({PluginHost? host}) : _host = host ?? PluginHost();

  final PluginHost _host;
  final Map<String, PluginDescriptor> _descriptors = {};
  final Map<String, Plugin> _plugins = {};

  List<PluginDescriptor> get descriptors => _descriptors.values.toList();
  List<String> get activeIds => _host.activeIds;

  void register(Plugin plugin) {
    _descriptors[plugin.id] = PluginDescriptor(manifest: plugin.manifest);
    _plugins[plugin.id] = plugin;
  }

  Future<void> enable(String id) async {
    final plugin = _plugins[id];
    final descriptor = _descriptors[id];
    if (plugin == null || descriptor == null) return;
    await _host.load(plugin);
    descriptor.status = _host.isActive(id)
        ? PluginStatus.enabled
        : PluginStatus.failed;
  }

  Future<void> disable(String id) async {
    final descriptor = _descriptors[id];
    if (descriptor == null) return;
    await _host.unload(id);
    descriptor.status = PluginStatus.disabled;
  }
}
