import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/security/application/encryption_service.dart';
import 'package:void_scriptor/core/security/crypto/encryption_cipher.dart';
import 'package:void_scriptor/core/security/crypto/key_derivation.dart';

/// core-hunt-20260906 BUG-36: encryptFile left the plaintext source on
/// disk after writing the .enc blob, defeating the stated purpose of
/// file-level at-rest encryption.
void main() {
  late Directory dir;
  late File source;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('core-hunt-20260906-bug36-');
    source = File('${dir.path}/secret.txt');
    await source.writeAsString('top secret', flush: true);
  });
  tearDown(() async {
    try {
      await dir.delete(recursive: true);
    } on FileSystemException catch (_) {}
  });

  Future<SecretKey> keyOf() => const Pbkdf2KeyDeriver().derive(
    passphrase: 'k36',
    salt: const [9, 8, 7, 6, 5, 4, 3, 2],
    iterations: 4,
    length: 32,
  );

  test(
    'default encryptFile removes the plaintext source after a successful write',
    () async {
      final service = EncryptedFileService(
        cipher: const AesGcmCipher(),
        directory: dir,
      );
      final key = await keyOf();

      final encPath = await service.encryptFile(key, source.path);

      expect(File(encPath).existsSync(), isTrue);
      expect(
        source.existsSync(),
        isFalse,
        reason: 'BUG-36: plaintext source survived encryption',
      );
      final decrypted = await service.decryptFile(key, encPath);
      expect(decrypted, 'top secret');
    },
  );

  test('deleteSource: false keeps the legacy copy behavior', () async {
    final service = EncryptedFileService(
      cipher: const AesGcmCipher(),
      directory: dir,
    );
    final key = await keyOf();

    await service.encryptFile(key, source.path, deleteSource: false);

    expect(source.existsSync(), isTrue);
  });

  test(
    'a failed encryption leaves the source untouched (no data loss)',
    () async {
      final service = EncryptedFileService(
        cipher: const AesGcmCipher(),
        directory: dir,
      );
      final key = await keyOf();

      // Force the .enc write to fail by making the output path a directory.
      final outDir = Directory('${dir.path}/secret.txt.enc');
      await outDir.create();

      await expectLater(
        service.encryptFile(key, source.path),
        throwsA(isA<FileSystemException>()),
      );
      expect(
        source.existsSync(),
        isTrue,
        reason: 'source must never be deleted when the .enc write failed',
      );
    },
  );
}
