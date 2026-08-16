import '../domain/plugin_manifest.dart';
import '../api/plugin.dart';
import '../sdk/plugin_context.dart';

/// Built-in demo plugin proving the SDK lifecycle end-to-end (Step 31.20).
class DemoPlugin extends Plugin {
  DemoPlugin()
    : super(
        PluginManifest.fromJson({
          'id': 'com.voidscriptor.demo',
          'name': 'Demo Plugin',
          'version': '1.0.0',
          'author': 'Void Scriptor',
          'apiVersion': '1.0',
          'capabilities': ['ui'],
          'permissions': ['storage'],
          'entrypoint': 'builtin',
        }),
      );

  @override
  Future<void> onActivate(PluginContext context) async {
    context.logger.info('DemoPlugin activated');
    await context.settings.set('activated', 'true');
  }
}
