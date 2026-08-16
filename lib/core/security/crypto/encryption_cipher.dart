import 'package:crypto/crypto.dart' as crypto;
import 'package:cryptography/cryptography.dart';

import 'key_derivation.dart' as ks;

/// Ciphertext envelope (Step 30.4).
class EncryptedBlob {
  const EncryptedBlob({
    required this.nonce,
    required this.ciphertext,
    required this.tag,
  });

  final List<int> nonce;
  final List<int> ciphertext;
  final List<int> tag;
}

/// Symmetric encryption contract (Step 30.4).
abstract interface class EncryptionCipher {
  Future<EncryptedBlob> encrypt(ks.SecretKey key, List<int> plaintext);
  Future<List<int>> decrypt(ks.SecretKey key, EncryptedBlob blob);
}

/// AES-256-GCM implementation via the pure-Dart `cryptography` package
/// (web-safe) (Step 30.5).
class AesGcmCipher implements EncryptionCipher {
  const AesGcmCipher();

  static final _algo = AesGcm.with256bits();

  @override
  Future<EncryptedBlob> encrypt(ks.SecretKey key, List<int> plaintext) async {
    final secretBox = await _algo.encrypt(
      plaintext,
      secretKey: SecretKeyData(key.bytes),
    );
    return EncryptedBlob(
      nonce: secretBox.nonce,
      ciphertext: secretBox.cipherText,
      tag: secretBox.mac.bytes,
    );
  }

  @override
  Future<List<int>> decrypt(ks.SecretKey key, EncryptedBlob blob) async {
    final clear = await _algo.decrypt(
      SecretBox(blob.ciphertext, nonce: blob.nonce, mac: Mac(blob.tag)),
      secretKey: SecretKeyData(key.bytes),
    );
    return clear;
  }
}

/// HMAC-SHA256 integrity signing (Step 30.6).
class HmacIntegrity {
  const HmacIntegrity();

  Future<List<int>> sign(ks.SecretKey key, List<int> data) async {
    return crypto.Hmac(crypto.sha256, key.bytes).convert(data).bytes;
  }

  Future<bool> verify(
    ks.SecretKey key,
    List<int> data,
    List<int> signature,
  ) async {
    final expected = await sign(key, data);
    if (expected.length != signature.length) return false;
    for (var i = 0; i < expected.length; i++) {
      if (expected[i] != signature[i]) return false;
    }
    return true;
  }
}
