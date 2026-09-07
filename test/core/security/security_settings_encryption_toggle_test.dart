import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/security/application/project_lock_service.dart';
import 'package:void_scriptor/core/security/crypto/encryption_cipher.dart';
import 'package:void_scriptor/core/security/crypto/key_derivation.dart';
import 'package:void_scriptor/core/security/presentation/security_settings_screen.dart';
import 'package:void_scriptor/database/project/project_database.dart';

/// core-hunt-20260906 BUG-44: the "Enkripsi Proyek" switch only mutated
/// local widget state — nothing persisted, no invariant enforced. It must
/// now reflect and drive the persisted `securitySettings.encryptionEnabled`
/// flag, and enabling requires a passphrase (the key source).
void main() {
  late ProjectDatabase db;
  late ProjectLockService service;

  setUp(() {
    db = ProjectDatabase(NativeDatabase.memory());
    service = ProjectLockService(
      database: db,
      deriver: const Pbkdf2KeyDeriver(),
      integrity: const HmacIntegrity(),
      defaultIterations: 4,
    );
  });
  tearDown(() async => db.close());

  group('ProjectLockService encryption setting', () {
    test('isEncryptionEnabled is false when no row exists', () async {
      expect(await service.isEncryptionEnabled('p1'), isFalse);
    });

    test(
      'setEncryptionEnabled without a passphrase is rejected and creates no row',
      () async {
        await expectLater(
          service.setEncryptionEnabled('p1', true),
          throwsA(isA<StateError>()),
        );
        expect(await service.isEncryptionEnabled('p1'), isFalse);
        final rows = await db.select(db.securitySettings).get();
        expect(rows, isEmpty);
      },
    );

    test(
      'setPassphrase enables encryption; disable then re-enable persists',
      () async {
        await service.setPassphrase('p1', 'correct horse battery staple');
        expect(await service.isEncryptionEnabled('p1'), isTrue);

        await service.setEncryptionEnabled('p1', false);
        expect(await service.isEncryptionEnabled('p1'), isFalse);

        await service.setEncryptionEnabled('p1', true);
        expect(await service.isEncryptionEnabled('p1'), isTrue);
        // The passphrase/lock state must survive the toggle.
        expect(await service.isLocked('p1'), isTrue);
      },
    );
  });

  group('SecuritySettingsScreen persistence', () {
    testWidgets('switch reflects persisted state and persists a disable', (
      tester,
    ) async {
      // setPassphrase derives via Isolate.run (BUG-31), whose completion is
      // not delivered inside the testWidgets FakeAsync zone — arrange the
      // row in a real async zone instead.
      await tester.runAsync(
        () => service.setPassphrase('p1', 'correct horse battery staple'),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: SecuritySettingsScreen(projectId: 'p1', database: db),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final switchFinder = find.byType(SwitchListTile);
      expect(tester.widget<SwitchListTile>(switchFinder).value, isTrue);

      await tester.tap(switchFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(await service.isEncryptionEnabled('p1'), isFalse);
    });

    testWidgets('enabling without a passphrase shows a message and stays off', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SecuritySettingsScreen(projectId: 'p1', database: db),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byType(SwitchListTile));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('passphrase'), findsOneWidget);
      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        isFalse,
      );
      expect(await service.isEncryptionEnabled('p1'), isFalse);
    });

    testWidgets('switch is disabled when there is no backing store', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: SecuritySettingsScreen()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).onChanged,
        isNull,
      );
    });
  });
}
