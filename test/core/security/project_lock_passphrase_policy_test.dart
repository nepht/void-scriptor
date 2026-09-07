import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/security/application/project_lock_service.dart';
import 'package:void_scriptor/core/security/crypto/encryption_cipher.dart';
import 'package:void_scriptor/core/security/crypto/key_derivation.dart';
import 'package:void_scriptor/database/project/project_database.dart';

void main() {
  group('core-hunt-20260906 passphrase policy (BUG-24/25)', () {
    late ProjectDatabase db;

    setUp(() => db = ProjectDatabase(NativeDatabase.memory()));
    tearDown(() async => db.close());

    ProjectLockService serviceWith({int iterations = 4}) => ProjectLockService(
      database: db,
      deriver: const Pbkdf2KeyDeriver(),
      integrity: const HmacIntegrity(),
      defaultIterations: iterations,
    );

    test('empty passphrase is rejected and leaves no lock row', () async {
      final service = serviceWith();
      await expectLater(
        service.setPassphrase('p1', ''),
        throwsA(isA<ArgumentError>()),
      );
      expect(await service.isLocked('p1'), isFalse);
    });

    test('whitespace-only passphrase is rejected', () async {
      final service = serviceWith();
      await expectLater(
        service.setPassphrase('p1', '   '),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('a passphrase set with one iteration count still unlocks after the '
        'service default changes', () async {
      final setter = serviceWith(iterations: 4);
      await setter.setPassphrase('p1', 's3cret');

      // App update raises the default: the stored per-row iteration
      // count must win, or every existing passphrase is bricked.
      final afterUpgrade = serviceWith(iterations: 8);
      expect(await afterUpgrade.unlock('p1', 's3cret'), isTrue);
      expect(await afterUpgrade.isLocked('p1'), isFalse);
    });

    test(
      'wrong passphrase still fails under the persisted iteration count',
      () async {
        final setter = serviceWith(iterations: 4);
        await setter.setPassphrase('p1', 's3cret');
        final afterUpgrade = serviceWith(iterations: 8);
        expect(await afterUpgrade.unlock('p1', 'nope'), isFalse);
        expect(await afterUpgrade.isLocked('p1'), isTrue);
      },
    );
  });
}
