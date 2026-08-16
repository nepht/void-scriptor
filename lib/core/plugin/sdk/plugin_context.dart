import 'plugin_logger.dart';
import 'plugin_settings_store.dart';

/// Bundle of SDK services handed to a plugin on activation (Step 31.6).
class PluginContext {
  const PluginContext({
    required this.pluginId,
    required this.logger,
    required this.settings,
  });

  final String pluginId;
  final PluginLogger logger;
  final PluginSettingsStore settings;
}
