import 'dart:convert';

import '../crypto/key_derivation.dart';
import '../crypto/encryption_cipher.dart';
import '../credential_store.dart';

/// Credential store that encrypts values before delegating (Step 30.10).
class EncryptedCredentialStore implements CredentialStore {
  EncryptedCredentialStore({
    required this.cipher,
    required this.key,
    required this.delegate,
  });

  final EncryptionCipher cipher;
  final SecretKey key;
  final CredentialStore delegate;

  String _encode(EncryptedBlob blob) {
    final nonce = base64Encode(blob.nonce);
    final tag = base64Encode(blob.tag);
    final ct = base64Encode(blob.ciphertext);
    return '$nonce.$tag.$ct';
  }

  EncryptedBlob _decode(String encoded) {
    final parts = encoded.split('.');
    return EncryptedBlob(
      nonce: base64Decode(parts[0]),
      tag: base64Decode(parts[1]),
      ciphertext: base64Decode(parts[2]),
    );
  }

  @override
  Future<void> write({required String key, required String value}) async {
    final blob = await cipher.encrypt(this.key, utf8.encode(value));
    await delegate.write(key: key, value: _encode(blob));
  }

  @override
  Future<String?> read(String key) async {
    final encoded = await delegate.read(key);
    if (encoded == null) return null;
    final bytes = await cipher.decrypt(this.key, _decode(encoded));
    return utf8.decode(bytes);
  }

  @override
  Future<void> delete(String key) => delegate.delete(key);
}
