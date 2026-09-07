import 'dart:convert';
import 'dart:isolate';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Immutable secret key bytes with explicit zeroing (Step 30.1).
class SecretKey {
  SecretKey(this._bytes);

  final List<int> _bytes;

  List<int> get bytes => List<int>.unmodifiable(_bytes);

  String get hex =>
      _bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  void zero() {
    for (var i = 0; i < _bytes.length; i++) {
      _bytes[i] = 0;
    }
  }
}

/// PBKDF2-HMAC-SHA256 key derivation (RFC 2898), built on `crypto` (Step 30.2).
class Pbkdf2KeyDeriver {
  const Pbkdf2KeyDeriver();

  /// Derives via PBKDF2-HMAC-SHA256. The heavy iteration loop runs on a
  /// short-lived worker isolate (core-hunt-20260906 BUG-31: previously the
  /// synchronous loop froze the calling — often UI — isolate for the full
  /// derivation, seconds at the default 100k iterations). Results are
  /// byte-identical to the former inline loop; message passing copies the
  /// inputs, so the caller's buffers are never aliased and the [SecretKey]
  /// zeroing contract is unchanged on both sides.
  Future<SecretKey> derive({
    required String passphrase,
    required List<int> salt,
    required int iterations,
    required int length,
  }) {
    return Isolate.run(() => _deriveSync(
          passphrase: passphrase,
          salt: salt,
          iterations: iterations,
          length: length,
        ));
  }

  static SecretKey _deriveSync({
    required String passphrase,
    required List<int> salt,
    required int iterations,
    required int length,
  }) {
    final passwordBytes = utf8.encode(passphrase);
    const hashLen = 32; // SHA-256
    final blockCount = (length / hashLen).ceil();
    final output = <int>[];

    for (var blockIndex = 1; blockIndex <= blockCount; blockIndex++) {
      final block = _pbkdf2Block(passwordBytes, salt, iterations, blockIndex);
      output.addAll(block);
    }
    return SecretKey(output.sublist(0, length));
  }

  static List<int> _pbkdf2Block(
    List<int> password,
    List<int> salt,
    int iterations,
    int blockIndex,
  ) {
    final saltWithIndex = <int>[
      ...salt,
      (blockIndex >> 24) & 0xFF,
      (blockIndex >> 16) & 0xFF,
      (blockIndex >> 8) & 0xFF,
      blockIndex & 0xFF,
    ];
    var u = Hmac(sha256, password).convert(saltWithIndex).bytes;
    final result = List<int>.from(u);
    for (var i = 1; i < iterations; i++) {
      u = Hmac(sha256, password).convert(u).bytes;
      for (var j = 0; j < result.length; j++) {
        result[j] ^= u[j];
      }
    }
    return result;
  }
}

/// Generates 32 cryptographically-random bytes (Step 30.3).
class MasterKeyGenerator {
  const MasterKeyGenerator();

  Future<SecretKey> generate() async {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return SecretKey(bytes);
  }
}
