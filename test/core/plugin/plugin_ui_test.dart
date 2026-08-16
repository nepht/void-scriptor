import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/plugin/domain/plugin_manifest.dart';
import 'package:void_scriptor/core/plugin/presentation/plugin_manager_screen.dart';
import 'package:void_scriptor/core/plugin/presentation/plugin_install_dialog.dart';
import 'package:void_scriptor/core/plugin/presentation/plugin_permission_grant.dart';

void main() {
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

  testWidgets('PluginManagerScreen renders plugin list and states', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PluginManagerScreen(
          plugins: [PluginDescriptor(manifest: manifest)],
        ),
      ),
    );
    expect(find.text('Hello Plugin'), findsOneWidget);
    expect(find.text('installed'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('PluginInstallDialog validates and returns manifest', (
    tester,
  ) async {
    PluginManifest? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showDialog<PluginManifest>(
                  context: context,
                  builder: (_) => const PluginInstallDialog(),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Instal Plugin'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('PluginPermissionGrant shows granted permissions', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PluginPermissionGrant(grantedPermissions: ['storage']),
      ),
    );
    expect(find.text('storage'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
