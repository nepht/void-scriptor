import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/plugin/domain/plugin_manifest.dart';
import 'package:void_scriptor/core/plugin/domain/plugin_api_version.dart';
import 'package:void_scriptor/core/plugin/api/plugin.dart';
import 'package:void_scriptor/core/plugin/host/plugin_host.dart';
import 'package:void_scriptor/core/plugin/host/plugin_registry.dart';

class _DemoPlugin extends Plugin {
  _DemoPlugin(super.manifest);

  bool activated = false;
  bool deactivated = false;

  @override
  Future<void> onActivate(context) async {
    activated = true;
  }

  @override
  Future<void> onDeactivate() async {
    deactivated = true;
  }
}

PluginManifest _manifest(String id) => PluginManifest.fromJson({
  'id': id,
  'name': id,
  'version': '1.0.0',
  'author': 't',
  'apiVersion': '1.0',
  'capabilities': <String>[],
  'permissions': <String>[],
  'entrypoint': 'main.dart',
});

void main() {
  test('Plugin exposes id and manifest', () {
    final plugin = _DemoPlugin(_manifest('a'));
    expect(plugin.id, 'a');
    expect(plugin.manifest.id, 'a');
  });

  test('PluginHost activates and deactivates a plugin', () async {
    final host = PluginHost();
    final plugin = _DemoPlugin(_manifest('a'));
    await host.load(plugin);
    expect(plugin.activated, isTrue);
    expect(host.activeIds, contains('a'));

    await host.unload('a');
    expect(plugin.deactivated, isTrue);
    expect(host.activeIds, isNot(contains('a')));
  });

  test('PluginHost rejects incompatible api version', () async {
    final host = PluginHost(hostApiVersion: const PluginApiVersion(2, 0));
    final plugin = _DemoPlugin(
      _manifest('old'),
    ); // requires 1.0, different major
    await host.load(plugin);
    expect(plugin.activated, isFalse);
    expect(host.activeIds, isEmpty);
  });

  test('PluginRegistry registers, enables, and lists', () async {
    final registry = PluginRegistry();
    final plugin = _DemoPlugin(_manifest('a'));
    registry.register(plugin);

    expect(registry.descriptors, hasLength(1));
    expect(registry.descriptors.first.status, PluginStatus.installed);

    await registry.enable('a');
    expect(registry.descriptors.first.status, PluginStatus.enabled);
    expect(registry.activeIds, contains('a'));

    await registry.disable('a');
    expect(registry.descriptors.first.status, PluginStatus.disabled);
    expect(registry.activeIds, isNot(contains('a')));
  });
}
