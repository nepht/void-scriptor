import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:archive/archive_io.dart';
import 'package:archive/archive.dart';
import '../../../core/security/application/secret_scanner.dart';
import 'portable_project_service.dart' show ArchiveIntegrity;

/// Contract: ".vscriptor manifest/checksums/secret exclusion".
///
/// Determines which package files must never leave the machine through a
/// portable (.voidproject) archive: credential files, key material, and
/// secret stores. Detection is filename-based (the only deterministic signal
/// available on an opaque file), content scanning is applied on top for
/// files whose names do not already identify them as secrets.
class ArchiveSecretPolicy {
  const ArchiveSecretPolicy._();

  /// Directory names that are treated as dedicated secret stores.
  static const String _envPrefix = '.env';
  static const _secretExtensions = <String>{
    '.pem',
    '.key',
    '.p12',
    '.pfx',
    '.kdbx',
    '.keystore',
    '.jks',
  };
  static const _secretBaseNames = <String>{
    'id_rsa',
    'id_dsa',
    'id_ecdsa',
    'id_ed25519',
    'credentials',
    'secrets',
    'credentials.json',
    'secrets.json',
    'credentials.yaml',
    'secrets.yaml',
  };
  static const _secretFolders = <String>{'.aws', '.ssh', '.gcloud', '.kube'};

  /// True when [entryName] (archive-relative, POSIX separators) refers to a
  /// file that must be excluded from portable archives.
  static bool isSecretPath(String entryName) {
    final backslash = String.fromCharCode(92);
    final normalized = entryName.replaceAll(backslash, '/');
    final segments = normalized.split('/');
    final name = segments.last;
    final lower = name.toLowerCase();
    if (lower == _envPrefix) return true;
    if (lower.startsWith('$_envPrefix.')) {
      // .env.example / .env.sample / .env.template are shareable templates.
      const safeSuffixes = ['.example', '.sample', '.template'];
      final isTemplate = safeSuffixes.any(lower.endsWith);
      if (!isTemplate) return true;
    }
    if (_secretBaseNames.contains(lower)) return true;
    for (final folder in _secretFolders) {
      if (segments.any((segment) => segment.toLowerCase() == folder)) {
        return true;
      }
    }
    final ext = _extensionOf(name);
    if (_secretExtensions.contains(ext)) return true;
    return false;
  }

  static String _extensionOf(String name) {
    final dot = name.lastIndexOf('.');
    if (dot <= 0) return '';
    if (dot == name.length - 1) return '';
    return name.substring(dot).toLowerCase();
  }

  /// Returns secret matches found in a non-secret file's content.
  static List<String> scanContent(String text) =>
      const SecretScanner().scan(text);

  static Future<void> assertNoSecrets(Directory stagingRoot) async {
    await for (final entity in stagingRoot.list(recursive: true)) {
      if (entity is! File) continue;
      final backslash = String.fromCharCode(92);
      final relative = p
          .relative(entity.path, from: stagingRoot.path)
          .replaceAll(backslash, '/');
      if (isSecretPath(relative)) {
        throw FormatException(
          'Archive staging contains a secret file: $relative',
        );
      }
      // Content scanning only for text-like files: opaque binaries (sqlite
      // database, images) must never fail a legitimate export on a random
      // byte coincidence.
      const textExtensions = {
        '.json',
        '.md',
        '.txt',
        '.yaml',
        '.yml',
        '.csv',
        '.xml',
        '.html',
      };
      if (!textExtensions.contains(_extensionOf(entity.path))) continue;
      final content = await entity.readAsBytes();
      if (content.isEmpty || content.length > 2 * 1024 * 1024) continue;
      if (const SecretScanner()
          .scan(utf8.decode(content, allowMalformed: true))
          .isNotEmpty) {
        throw FormatException(
          'Archive staging contains a secret-like payload: $relative',
        );
      }
    }
  }

  /// Import-side defense in depth: refuses archives whose entries include a
  /// secret path, even when the archive checksum itself is valid.
  static void assertArchiveHasNoSecrets(Archive archive) {
    for (final entry in archive) {
      if (!entry.isFile || entry.name == ArchiveIntegrity.manifestEntryName) {
        continue;
      }
      if (isSecretPath(entry.name)) {
        throw FormatException('Archive contains a secret file: ${entry.name}');
      }
    }
  }
}
