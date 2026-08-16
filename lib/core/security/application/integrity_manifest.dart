import 'dart:io';

import 'package:path/path.dart' as p;

import '../crypto/key_derivation.dart';
import '../crypto/encryption_cipher.dart';

class IntegrityEntry {
  const IntegrityEntry({required this.relativePath, required this.signature});

  final String relativePath;
  final List<int> signature;
}

/// Builds and verifies a per-file HMAC integrity manifest (Step 30.15).
class IntegrityManifest {
  const IntegrityManifest();

  Future<List<IntegrityEntry>> build(
    Directory directory,
    SecretKey key, {
    required HmacIntegrity integrity,
  }) async {
    final entries = <IntegrityEntry>[];
    await for (final entity in directory.list(recursive: true)) {
      if (entity is! File) continue;
      final rel = p.relative(entity.path, from: directory.path);
      final bytes = await entity.readAsBytes();
      final signature = await integrity.sign(key, bytes);
      entries.add(IntegrityEntry(relativePath: rel, signature: signature));
    }
    entries.sort((a, b) => a.relativePath.compareTo(b.relativePath));
    return entries;
  }

  Future<bool> verify(
    Directory directory,
    List<IntegrityEntry> entries,
    SecretKey key, {
    required HmacIntegrity integrity,
  }) async {
    for (final entry in entries) {
      final file = File(p.join(directory.path, entry.relativePath));
      if (!await file.exists()) return false;
      final bytes = await file.readAsBytes();
      final valid = await integrity.verify(key, bytes, entry.signature);
      if (!valid) return false;
    }
    return true;
  }
}
