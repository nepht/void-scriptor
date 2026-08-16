import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/security/crypto/key_derivation.dart';
import 'package:void_scriptor/core/security/crypto/encryption_cipher.dart';
import 'package:void_scriptor/core/security/application/encryption_service.dart';

void main() {
  late SecretKey key;

  setUpAll(() async {
    key = await const MasterKeyGenerator().generate();
  });

  test('encryptString then decryptString roundtrips', () async {
    final service = EncryptionService(cipher: const AesGcmCipher());
    final encrypted = await service.encryptString(key, 'secret data');
    final decrypted = await service.decryptString(key, encrypted);
    expect(decrypted, 'secret data');
  });

  test('encryptBytes then decryptBytes roundtrips', () async {
    final service = EncryptionService(cipher: const AesGcmCipher());
    final bytes = utf8.encode('binary payload');
    final encrypted = await service.encryptBytes(key, bytes);
    final decrypted = await service.decryptBytes(key, encrypted);
    expect(decrypted, bytes);
  });

  test('EncryptedFileService writes .enc and decrypts back', () async {
    final dir = Directory.systemTemp.createTempSync('vs_enc_');
    addTearDown(() => dir.deleteSync(recursive: true));

    final service = EncryptedFileService(
      cipher: const AesGcmCipher(),
      directory: dir,
    );
    final source = File('${dir.path}/plain.txt');
    await source.writeAsString('top secret');

    final encPath = await service.encryptFile(key, source.path);
    expect(encPath, endsWith('.enc'));
    expect(File(encPath).existsSync(), isTrue);
    expect(
      utf8.decode(File(encPath).readAsBytesSync(), allowMalformed: true),
      isNot(contains('top secret')),
    );

    final decrypted = await service.decryptFile(key, encPath);
    expect(decrypted, 'top secret');
  });
}
