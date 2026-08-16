import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/security/crypto/key_derivation.dart';

void main() {
  test('SecretKey stores raw bytes and exposes hex', () {
    final key = SecretKey(List<int>.generate(32, (i) => i));
    expect(key.bytes, hasLength(32));
    expect(key.hex, isNotEmpty);
    expect(key.hex, contains('00'));
  });

  test('SecretKey.zero clears the backing bytes', () {
    final key = SecretKey(List<int>.filled(32, 0xAB));
    key.zero();
    expect(key.bytes, everyElement(0));
  });

  test('Pbkdf2KeyDeriver is deterministic for same inputs', () async {
    const deriver = Pbkdf2KeyDeriver();
    final a = await deriver.derive(
      passphrase: 'correct horse',
      salt: List<int>.filled(16, 1),
      iterations: 1000,
      length: 32,
    );
    final b = await deriver.derive(
      passphrase: 'correct horse',
      salt: List<int>.filled(16, 1),
      iterations: 1000,
      length: 32,
    );
    expect(a.bytes, b.bytes);
  });

  test('Pbkdf2KeyDeriver differs for different passphrase', () async {
    const deriver = Pbkdf2KeyDeriver();
    final a = await deriver.derive(
      passphrase: 'alpha',
      salt: List<int>.filled(16, 1),
      iterations: 1000,
      length: 32,
    );
    final b = await deriver.derive(
      passphrase: 'beta',
      salt: List<int>.filled(16, 1),
      iterations: 1000,
      length: 32,
    );
    expect(a.bytes, isNot(equals(b.bytes)));
  });

  test(
    'MasterKeyGenerator produces 32 secure bytes, unique each call',
    () async {
      const gen = MasterKeyGenerator();
      final a = await gen.generate();
      final b = await gen.generate();
      expect(a.bytes, hasLength(32));
      expect(a.bytes, isNot(equals(b.bytes)));
    },
  );

  test('deriveKeyFromPassphrase helper roundtrips through utf8', () async {
    const deriver = Pbkdf2KeyDeriver();
    final key = await deriver.derive(
      passphrase: 'test',
      salt: utf8.encode('salt'),
      iterations: 10,
      length: 32,
    );
    expect(key.bytes, hasLength(32));
  });
}
