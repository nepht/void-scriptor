import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/core/security/crypto/key_derivation.dart';
import 'package:void_scriptor/core/security/crypto/encryption_cipher.dart';
import 'package:void_scriptor/core/security/application/project_lock_service.dart';
import 'package:void_scriptor/core/security/application/integrity_manifest.dart';

void main() {
  group('ProjectLockService', () {
    late ProjectDatabase db;
    late ProjectLockService service;

    setUp(() {
      db = ProjectDatabase(NativeDatabase.memory());
      service = ProjectLockService(
        database: db,
        deriver: const Pbkdf2KeyDeriver(),
        integrity: const HmacIntegrity(),
      );
    });

    tearDown(() async => db.close());

    test('setPassphrase then unlock with correct passphrase', () async {
      await service.setPassphrase('p1', 's3cret');
      expect(await service.isLocked('p1'), isTrue);
      expect(await service.unlock('p1', 's3cret'), isTrue);
      expect(await service.isLocked('p1'), isFalse);
    });

    test('unlock fails with wrong passphrase', () async {
      await service.setPassphrase('p1', 'correct');
      expect(await service.unlock('p1', 'wrong'), isFalse);
      expect(await service.isLocked('p1'), isTrue);
    });

    test('lock re-locks the project', () async {
      await service.setPassphrase('p1', 'secret');
      await service.unlock('p1', 'secret');
      await service.lock('p1');
      expect(await service.isLocked('p1'), isTrue);
    });
  });

  group('IntegrityManifest', () {
    test('builds and verifies a file manifest', () async {
      final dir = Directory.systemTemp.createTempSync('vs_int_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File('${dir.path}/data.txt');
      await file.writeAsString('integrity payload');

      const manifest = IntegrityManifest();
      const integrity = HmacIntegrity();
      final key = await const MasterKeyGenerator().generate();
      final entries = await manifest.build(dir, key, integrity: integrity);
      expect(entries, isNotEmpty);
      expect(entries.first.relativePath, 'data.txt');
      expect(
        await manifest.verify(dir, entries, key, integrity: integrity),
        isTrue,
      );
    });

    test('verify fails after tampering', () async {
      final dir = Directory.systemTemp.createTempSync('vs_int2_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File('${dir.path}/data.txt');
      await file.writeAsString('original');

      const manifest = IntegrityManifest();
      const integrity = HmacIntegrity();
      final key = await const MasterKeyGenerator().generate();
      final entries = await manifest.build(dir, key, integrity: integrity);
      await file.writeAsString('tampered');
      expect(
        await manifest.verify(dir, entries, key, integrity: integrity),
        isFalse,
      );
    });
  });
}
