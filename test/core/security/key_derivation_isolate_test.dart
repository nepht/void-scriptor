import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/security/crypto/key_derivation.dart';

/// Reference copy of the original synchronous PBKDF2-HMAC-SHA256 block
/// loop, used to prove the offloaded implementation is byte-identical.
List<int> _referenceDerive(
  String passphrase,
  List<int> salt,
  int iterations,
  int length,
) {
  final password = utf8.encode(passphrase);
  const hashLen = 32;
  final output = <int>[];
  for (
    var blockIndex = 1;
    blockIndex <= (length / hashLen).ceil();
    blockIndex++
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
    output.addAll(result);
  }
  return output.sublist(0, length);
}

void main() {
  group('core-hunt-20260906 PBKDF2 isolate offload (BUG-31)', () {
    test('derive() returns control to the calling isolate immediately while '
        'a heavy (200k-iteration) derivation runs off-thread', () async {
      const deriver = Pbkdf2KeyDeriver();
      final stopwatch = Stopwatch()..start();
      final future = deriver.derive(
        passphrase: 'long-enough-passphrase',
        salt: const [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16],
        iterations: 200000,
        length: 32,
      );
      final returnedAfterMs = stopwatch.elapsedMilliseconds;
      final key = await future;

      expect(key.bytes.length, 32);
      // The synchronous loop costs seconds on this host; returning in
      // well under a second proves the work left the calling isolate.
      expect(
        returnedAfterMs,
        lessThan(500),
        reason: 'derive() blocked the calling isolate (BUG-31)',
      );
    });

    test(
      'offloaded derivation is byte-identical to the reference loop',
      () async {
        const deriver = Pbkdf2KeyDeriver();
        final key = await deriver.derive(
          passphrase: 'determinism-check',
          salt: const [9, 8, 7, 6, 5, 4, 3, 2, 1, 0],
          iterations: 1000,
          length: 32,
        );
        expect(
          key.bytes,
          _referenceDerive(
            'determinism-check',
            const [9, 8, 7, 6, 5, 4, 3, 2, 1, 0],
            1000,
            32,
          ),
        );
      },
    );
  });
}
