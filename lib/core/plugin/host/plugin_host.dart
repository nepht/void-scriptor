import '../domain/plugin_api_version.dart';
import '../api/plugin.dart';
import '../sdk/plugin_context.dart';
import '../sdk/plugin_logger.dart';
import '../sdk/plugin_settings_store.dart';

/// Manages plugin lifecycle: load → validate → activate → deactivate (Step 31.8).
class PluginHost {
  PluginHost({this.hostApiVersion = const PluginApiVersion(1, 0)});

  final PluginApiVersion hostApiVersion;
  final Map<String, _ActivePlugin> _active = {};

  List<String> get activeIds => _active.keys.toList();

  bool isActive(String id) => _active.containsKey(id);

  Future<void> load(Plugin plugin) async {
    if (!plugin.manifest.apiVersion.isCompatibleWith(hostApiVersion)) {
      return;
    }
    if (_active.containsKey(plugin.id)) return;
    final context = PluginContext(
      pluginId: plugin.id,
      logger: PluginLogger(pluginId: plugin.id),
      settings: PluginSettingsStore(),
    );
    await plugin.onActivate(context);
    _active[plugin.id] = _ActivePlugin(plugin, context);
  }

  Future<void> unload(String id) async {
    final active = _active.remove(id);
    if (active == null) return;
    await active.plugin.onDeactivate();
    await active.plugin.dispose();
  }
}

class _ActivePlugin {
  _ActivePlugin(this.plugin, this.context);
  final Plugin plugin;
  final PluginContext context;
}
