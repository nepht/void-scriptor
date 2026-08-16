import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/security/crypto/key_derivation.dart';
import 'package:void_scriptor/core/security/crypto/encryption_cipher.dart';
import 'package:void_scriptor/core/security/credential_store.dart';
import 'package:void_scriptor/core/security/application/encrypted_credential_store.dart';
import 'package:void_scriptor/core/security/application/secret_redactor.dart';
import 'package:void_scriptor/core/security/application/secret_scanner.dart';

void main() {
  late SecretKey key;

  setUpAll(() async {
    key = await const MasterKeyGenerator().generate();
  });

  group('EncryptedCredentialStore', () {
    test('writes encrypted and reads back plaintext', () async {
      final backing = MemoryCredentialStore();
      final store = EncryptedCredentialStore(
        cipher: const AesGcmCipher(),
        key: key,
        delegate: backing,
      );
      await store.write(key: 'api_key', value: 'sk-super-secret');
      // Backing store must not contain the plaintext.
      final raw = await backing.read('api_key');
      expect(raw, isNotNull);
      expect(raw, isNot(contains('sk-super-secret')));

      final value = await store.read('api_key');
      expect(value, 'sk-super-secret');
    });

    test('delete removes the entry', () async {
      final store = EncryptedCredentialStore(
        cipher: const AesGcmCipher(),
        key: key,
        delegate: MemoryCredentialStore(),
      );
      await store.write(key: 'k', value: 'v');
      await store.delete('k');
      expect(await store.read('k'), isNull);
    });
  });

  group('SecretRedactor', () {
    test('masks API keys', () {
      const redactor = SecretRedactor();
      expect(redactor.mask('sk-abcdefghijklmnop'), 'sk-****');
      expect(redactor.mask(''), '');
      expect(redactor.mask('abc'), '****');
    });

    test('redacts secrets from log lines', () {
      const redactor = SecretRedactor();
      const log = 'call openai with key=sk-1234567890 and token=abc';
      final cleaned = redactor.redact(log, secrets: ['sk-1234567890', 'abc']);
      expect(cleaned, isNot(contains('sk-1234567890')));
      expect(cleaned, isNot(contains('abc')));
      expect(cleaned, contains('[REDACTED]'));
    });
  });

  group('SecretScanner', () {
    test('detects common secret patterns', () {
      const scanner = SecretScanner();
      expect(scanner.scan('sk-1234567890abcdef').isNotEmpty, isTrue);
      expect(scanner.scan('AKIAIOSFODNN7EXAMPLE').isNotEmpty, isTrue);
      expect(scanner.scan('normal text without secrets').isEmpty, isTrue);
    });
  });
}
