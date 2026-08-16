import '../domain/plugin_manifest.dart';
import '../sdk/plugin_context.dart';

/// Contract every plugin implements (Step 31.7).
abstract class Plugin {
  Plugin(this.manifest);

  final PluginManifest manifest;

  String get id => manifest.id;

  Future<void> onActivate(PluginContext context) async {}
  Future<void> onDeactivate() async {}
  Future<void> dispose() async {}
}
