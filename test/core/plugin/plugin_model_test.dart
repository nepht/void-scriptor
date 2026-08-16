import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/plugin/domain/plugin_api_version.dart';
import 'package:void_scriptor/core/plugin/domain/plugin_manifest.dart';

void main() {
  test('PluginApiVersion parses and compares', () {
    final v = PluginApiVersion.parse('2.3');
    expect(v.major, 2);
    expect(v.minor, 3);
    // Plugin 2.3 runs on host 2.5 (major match, host minor >= plugin minor).
    expect(v.isCompatibleWith(const PluginApiVersion(2, 5)), isTrue);
    // Host 2.0 is too old for a plugin requiring 2.3.
    expect(v.isCompatibleWith(const PluginApiVersion(2, 0)), isFalse);
    // Different major never compatible.
    expect(v.isCompatibleWith(const PluginApiVersion(3, 0)), isFalse);
  });

  test('PluginApiVersion rejects malformed input', () {
    expect(() => PluginApiVersion.parse('abc'), throwsFormatException);
    expect(() => PluginApiVersion.parse('1'), throwsFormatException);
  });

  test('PluginManifest parses valid JSON', () {
    final manifest = PluginManifest.fromJson({
      'id': 'com.example.hello',
      'name': 'Hello Plugin',
      'version': '1.0.0',
      'author': 'Example',
      'apiVersion': '1.0',
      'capabilities': ['ui'],
      'permissions': ['storage'],
      'entrypoint': 'main.dart',
    });
    expect(manifest.id, 'com.example.hello');
    expect(manifest.name, 'Hello Plugin');
    expect(manifest.apiVersion.major, 1);
    expect(manifest.capabilities, ['ui']);
    expect(manifest.permissions, ['storage']);
  });

  test('PluginManifest rejects missing required field', () {
    expect(
      () => PluginManifest.fromJson({'name': 'missing id'}),
      throwsA(isA<PluginManifestException>()),
    );
  });

  test('PluginDescriptor wraps manifest with status', () {
    final manifest = PluginManifest.fromJson({
      'id': 'com.example.x',
      'name': 'X',
      'version': '1.0.0',
      'author': 'A',
      'apiVersion': '1.0',
      'capabilities': <String>[],
      'permissions': <String>[],
      'entrypoint': 'main.dart',
    });
    final descriptor = PluginDescriptor(manifest: manifest);
    expect(descriptor.status, PluginStatus.installed);
    expect(descriptor.id, 'com.example.x');
  });
}
