import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/security/crypto/key_derivation.dart';
import 'package:void_scriptor/core/security/crypto/encryption_cipher.dart';

void main() {
  late SecretKey key;

  setUpAll(() async {
    key = await const MasterKeyGenerator().generate();
  });

  test('EncryptedBlob exposes nonce, ciphertext, and tag', () {
    final blob = EncryptedBlob(
      nonce: List<int>.filled(12, 3),
      ciphertext: List<int>.filled(16, 7),
      tag: List<int>.filled(16, 9),
    );
    expect(blob.nonce, hasLength(12));
    expect(blob.ciphertext, hasLength(16));
    expect(blob.tag, hasLength(16));
  });

  test('AesGcmCipher encrypts then decrypts back to original bytes', () async {
    const cipher = AesGcmCipher();
    final plaintext = utf8.encode('Void Scriptor secret payload');
    final blob = await cipher.encrypt(key, plaintext);
    final decrypted = await cipher.decrypt(key, blob);
    expect(decrypted, plaintext);
  });

  test('AesGcmCipher produces different blobs for same plaintext', () async {
    const cipher = AesGcmCipher();
    final plaintext = utf8.encode('same');
    final a = await cipher.encrypt(key, plaintext);
    final b = await cipher.encrypt(key, plaintext);
    expect(a.ciphertext, isNot(equals(b.ciphertext)));
  });

  test('AesGcmCipher fails to decrypt with wrong key', () async {
    const cipher = AesGcmCipher();
    final wrongKey = await const MasterKeyGenerator().generate();
    final blob = await cipher.encrypt(key, utf8.encode('data'));
    expect(() => cipher.decrypt(wrongKey, blob), throwsA(isA<Exception>()));
  });

  test('HmacIntegrity signs and verifies', () async {
    const integrity = HmacIntegrity();
    final data = utf8.encode('message');
    final signature = await integrity.sign(key, data);
    expect(signature, isNotEmpty);
    expect(await integrity.verify(key, data, signature), isTrue);
  });

  test('HmacIntegrity rejects tampered data', () async {
    const integrity = HmacIntegrity();
    final data = utf8.encode('message');
    final signature = await integrity.sign(key, data);
    final tampered = utf8.encode('Message');
    expect(await integrity.verify(key, tampered, signature), isFalse);
  });
}
