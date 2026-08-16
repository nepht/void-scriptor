import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/security/presentation/project_lock_screen.dart';
import 'package:void_scriptor/core/security/presentation/security_settings_screen.dart';
import 'package:void_scriptor/core/security/presentation/secret_visibility_toggle.dart';

void main() {
  testWidgets('ProjectLockScreen renders passphrase field and unlock button', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: ProjectLockScreen(projectName: 'Demo')),
    );
    expect(find.text('Demo terkunci'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Buka Proyek'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ProjectLockScreen invokes onUnlock with passphrase', (
    tester,
  ) async {
    String? submitted;
    await tester.pumpWidget(
      MaterialApp(
        home: ProjectLockScreen(
          projectName: 'Demo',
          onUnlock: (pass) => submitted = pass,
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 's3cret');
    await tester.tap(find.text('Buka Proyek'));
    await tester.pump();
    expect(submitted, 's3cret');
  });

  testWidgets('SecuritySettingsScreen renders enable and change controls', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SecuritySettingsScreen()));
    expect(find.text('Enkripsi Proyek'), findsOneWidget);
    expect(find.text('Ubah Passphrase'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('SecretVisibilityToggle masks and reveals', (tester) async {
    bool hidden = true;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SecretVisibilityToggle(
            hidden: hidden,
            onChanged: (v) => hidden = v,
          ),
        ),
      ),
    );
    // Default icon: visibility_off (hidden).
    expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    await tester.tap(find.byType(IconButton));
    await tester.pump();
    expect(hidden, isFalse);
  });
}
