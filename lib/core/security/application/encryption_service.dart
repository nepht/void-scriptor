import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../crypto/key_derivation.dart';
import '../crypto/encryption_cipher.dart';

/// High-level encryption for bytes and strings (Step 30.7).
class EncryptionService {
  const EncryptionService({required this.cipher});

  final EncryptionCipher cipher;

  Future<EncryptedBlob> encryptBytes(SecretKey key, List<int> bytes) =>
      cipher.encrypt(key, bytes);

  Future<List<int>> decryptBytes(SecretKey key, EncryptedBlob blob) =>
      cipher.decrypt(key, blob);

  Future<EncryptedBlob> encryptString(SecretKey key, String value) =>
      encryptBytes(key, utf8.encode(value));

  Future<String> decryptString(SecretKey key, EncryptedBlob blob) async {
    final bytes = await decryptBytes(key, blob);
    return utf8.decode(bytes);
  }
}

/// File-level at-rest encryption (Step 30.8).
class EncryptedFileService {
  const EncryptedFileService({required this.cipher, required this.directory});

  final EncryptionCipher cipher;
  final Directory directory;

  /// Encrypts [sourcePath] and writes `<name>.enc` into [directory].
  ///
  /// core-hunt-20260906 BUG-36: the plaintext source used to survive the
  /// call, defeating the stated purpose of at-rest encryption. The source
  /// is now deleted after a successful `.enc` write; pass
  /// [deleteSource] = false for the legacy copy behavior. A failed
  /// encryption (or failed `.enc` write) never touches the source.
  Future<String> encryptFile(
    SecretKey key,
    String sourcePath, {
    bool deleteSource = true,
  }) async {
    await directory.create(recursive: true);
    final source = File(sourcePath);
    final bytes = await source.readAsBytes();
    final blob = await cipher.encrypt(key, bytes);
    final outPath = p.join(directory.path, '${p.basename(sourcePath)}.enc');
    await File(outPath).writeAsBytes(_encodeBlob(blob));
    if (deleteSource) {
      await source.delete();
    }
    return outPath;
  }

  /// Decrypts `<name>.enc` at [encPath] and returns its UTF-8 content.
  Future<String> decryptFile(SecretKey key, String encPath) async {
    final bytes = await File(encPath).readAsBytes();
    final blob = _decodeBlob(bytes);
    final clear = await cipher.decrypt(key, blob);
    return utf8.decode(clear);
  }

  List<int> _encodeBlob(EncryptedBlob blob) {
    // Layout: [nonceLen(4)][nonce][tagLen(4)][tag][ciphertext]
    final nonceLen = blob.nonce.length;
    final tagLen = blob.tag.length;
    final out = <int>[
      (nonceLen >> 24) & 0xFF,
      (nonceLen >> 16) & 0xFF,
      (nonceLen >> 8) & 0xFF,
      nonceLen & 0xFF,
      ...blob.nonce,
      (tagLen >> 24) & 0xFF,
      (tagLen >> 16) & 0xFF,
      (tagLen >> 8) & 0xFF,
      tagLen & 0xFF,
      ...blob.tag,
      ...blob.ciphertext,
    ];
    return out;
  }

  EncryptedBlob _decodeBlob(List<int> bytes) {
    final nonceLen = _readInt(bytes, 0);
    final nonce = bytes.sublist(4, 4 + nonceLen);
    final tagLenOffset = 4 + nonceLen;
    final tagLen = _readInt(bytes, tagLenOffset);
    final tagStart = tagLenOffset + 4;
    final tag = bytes.sublist(tagStart, tagStart + tagLen);
    final ciphertext = bytes.sublist(tagStart + tagLen);
    return EncryptedBlob(nonce: nonce, ciphertext: ciphertext, tag: tag);
  }

  int _readInt(List<int> bytes, int offset) =>
      (bytes[offset] << 24) |
      (bytes[offset + 1] << 16) |
      (bytes[offset + 2] << 8) |
      bytes[offset + 3];
}
