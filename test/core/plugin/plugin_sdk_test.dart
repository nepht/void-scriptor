import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/plugin/sdk/plugin_logger.dart';
import 'package:void_scriptor/core/plugin/sdk/plugin_settings_store.dart';
import 'package:void_scriptor/core/plugin/sdk/plugin_context.dart';

void main() {
  test('PluginLogger buffers scoped messages', () {
    final logger = PluginLogger(pluginId: 'p1');
    logger.info('hello');
    logger.warn('careful');
    logger.error('boom');
    final entries = logger.entries;
    expect(entries, hasLength(3));
    expect(entries.first.level, PluginLogLevel.info);
    expect(entries.first.message, contains('[p1]'));
    expect(entries.last.level, PluginLogLevel.error);
  });

  test('PluginSettingsStore persists key-value and removes', () async {
    final store = PluginSettingsStore();
    await store.set('theme', 'dark');
    expect(await store.get('theme'), 'dark');
    expect(await store.get('missing'), isNull);
    await store.remove('theme');
    expect(await store.get('theme'), isNull);
  });

  test('PluginContext bundles logger + settings', () {
    final logger = PluginLogger(pluginId: 'p1');
    final settings = PluginSettingsStore();
    final context = PluginContext(
      pluginId: 'p1',
      logger: logger,
      settings: settings,
    );
    expect(context.pluginId, 'p1');
    expect(context.logger, same(logger));
    expect(context.settings, same(settings));
  });
}
