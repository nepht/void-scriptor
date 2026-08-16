import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/plugin/domain/plugin_manifest.dart';
import 'package:void_scriptor/core/plugin/sandbox/plugin_permission.dart';
import 'package:void_scriptor/core/plugin/sandbox/plugin_sandbox.dart';

void main() {
  test('PluginPermission parses from string and rejects unknown', () {
    expect(PluginPermission.fromName('storage'), PluginPermission.storage);
    expect(PluginPermission.fromName('network'), PluginPermission.network);
    expect(() => PluginPermission.fromName('bogus'), throwsArgumentError);
  });

  test('PluginSandbox grants access for declared permission', () {
    final sandbox = PluginSandbox(granted: {PluginPermission.storage});
    expect(sandbox.canAccess(PluginPermission.storage), isTrue);
    expect(sandbox.canAccess(PluginPermission.network), isFalse);
  });

  test('PluginSandbox.require throws when permission missing', () {
    final sandbox = PluginSandbox(granted: {PluginPermission.ui});
    expect(
      () => sandbox.require(PluginPermission.network),
      throwsA(isA<PluginPermissionDenied>()),
    );
  });

  test('PluginPermissionSet validates manifest permissions', () {
    final valid = PluginPermissionSet.validate(['storage', 'ui']);
    expect(valid, {PluginPermission.storage, PluginPermission.ui});

    expect(
      () => PluginPermissionSet.validate(['storage', 'nope']),
      throwsA(isA<PluginManifestException>()),
    );
  });
}
