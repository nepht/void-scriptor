import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/security/application/integrity_manifest.dart';
import 'package:void_scriptor/core/security/crypto/encryption_cipher.dart';
import 'package:void_scriptor/core/security/crypto/key_derivation.dart';

/// core-hunt-20260906 BUG-34: verify() only checked the manifest's own
/// entries — files ADDED after signing went undetected.
void main() {
  late Directory dir;
  const integrity = HmacIntegrity();

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('core-hunt-20260906-bug34-');
    await File('${dir.path}/a.txt').writeAsString('alpha', flush: true);
    await File('${dir.path}/b.txt').writeAsString('beta', flush: true);
  });
  tearDown(() async {
    try {
      await dir.delete(recursive: true);
    } on FileSystemException catch (_) {}
  });

  Future<SecretKey> keyOf(String seed) => const Pbkdf2KeyDeriver().derive(
        passphrase: seed,
        salt: const [1, 2, 3, 4, 5, 6, 7, 8],
        iterations: 4,
        length: 32,
      );

  test('a file added after signing fails verification', () async {
    final key = await keyOf('k34');
    const manifest = IntegrityManifest();
    final entries = await manifest.build(dir, key, integrity: integrity);
    expect(await manifest.verify(dir, entries, key, integrity: integrity), isTrue);

    await File('${dir.path}/smuggled.txt').writeAsString('extra', flush: true);
    expect(
      await manifest.verify(dir, entries, key, integrity: integrity),
      isFalse,
      reason: 'BUG-34: post-signing additions were never compared',
    );
  });

  test('a file deleted after signing fails verification (already covered)', () async {
    final key = await keyOf('k34b');
    const manifest = IntegrityManifest();
    final entries = await manifest.build(dir, key, integrity: integrity);
    await File('${dir.path}/b.txt').delete();
    expect(await manifest.verify(dir, entries, key, integrity: integrity), isFalse);
  });

  test('an unchanged directory still verifies', () async {
    final key = await keyOf('k34c');
    const manifest = IntegrityManifest();
    final entries = await manifest.build(dir, key, integrity: integrity);
    expect(await manifest.verify(dir, entries, key, integrity: integrity), isTrue);
  });

  test('a tampered file still fails verification (existing contract)', () async {
    final key = await keyOf('k34d');
    const manifest = IntegrityManifest();
    final entries = await manifest.build(dir, key, integrity: integrity);
    await File('${dir.path}/a.txt').writeAsString('tampered', flush: true);
    expect(await manifest.verify(dir, entries, key, integrity: integrity), isFalse);
  });
}
