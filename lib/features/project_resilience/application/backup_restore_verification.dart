import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../../../core/project_package/project_package.dart';
import 'project_backup_restore_preview.dart';

/// Result of verifying a backup without overwriting the live project.
final class BackupRestoreVerificationReport {
  const BackupRestoreVerificationReport({
    required this.completeBackup,
    required this.mediaIncluded,
    required this.restoreCleanInstall,
    required this.linksPreserved,
    required this.settingsPreserved,
    required this.warnings,
  });

  final bool completeBackup;
  final bool mediaIncluded;
  final bool restoreCleanInstall;
  final bool linksPreserved;
  final bool settingsPreserved;
  final List<String> warnings;
}

/// Verifies the portable backup payload by restoring it into a new package.
/// The live package and the backup directory are never used as restore targets.
final class BackupRestoreVerificationService {
  Future<BackupRestoreVerificationReport> verify({
    required ProjectPackage package,
    required Directory backup,
    required Directory cleanInstallRoot,
  }) async {
    final warnings = <String>[];
    final metadataFile = File(p.join(backup.path, 'backup.json'));
    final manifestFile = File(p.join(backup.path, 'project.json'));
    final databaseFile = File(p.join(backup.path, 'project.db'));
    final complete =
        await metadataFile.exists() &&
        await manifestFile.exists() &&
        await databaseFile.exists();
    if (!complete) {
      return const BackupRestoreVerificationReport(
        completeBackup: false,
        mediaIncluded: false,
        restoreCleanInstall: false,
        linksPreserved: false,
        settingsPreserved: false,
        warnings: ['Backup is missing a required core file.'],
      );
    }

    final decoded = jsonDecode(await metadataFile.readAsString());
    final files = decoded is Map<String, dynamic> ? decoded['files'] : null;
    final checksumsMatch =
        files is Map<String, dynamic> &&
        files['project.json'] == await _sha256(manifestFile) &&
        files['project.db'] == await _sha256(databaseFile);
    if (!checksumsMatch) {
      warnings.add('Core backup checksum mismatch.');
    }

    final restored =
        await ProjectBackupRestorePreview.restoreToAlternateDestination(
          backup: backup,
          destinationRoot: cleanInstallRoot,
        );
    final restoredManifest = await _sha256(restored.manifestFile);
    final restoredDatabase = await _sha256(restored.databaseFile);
    final settingsPreserved = restoredManifest == await _sha256(manifestFile);
    final linksPreserved = restoredDatabase == await _sha256(databaseFile);
    final sourceAssets = await _checksums(
      Directory(p.join(backup.path, 'assets')),
    );
    final restoredAssets = await _checksums(restored.assetsDirectory);
    final mediaIncluded =
        sourceAssets.isNotEmpty &&
        sourceAssets.length == restoredAssets.length &&
        sourceAssets.entries.every(
          (entry) => restoredAssets[entry.key] == entry.value,
        );
    if (!settingsPreserved) {
      warnings.add('Project settings did not round-trip.');
    }
    if (!linksPreserved) {
      warnings.add('Database/link payload did not round-trip.');
    }
    if (sourceAssets.isNotEmpty && !mediaIncluded) {
      warnings.add('Media payload did not round-trip.');
    }

    return BackupRestoreVerificationReport(
      completeBackup: checksumsMatch,
      mediaIncluded: mediaIncluded,
      restoreCleanInstall: true,
      linksPreserved: linksPreserved,
      settingsPreserved: settingsPreserved,
      warnings: List.unmodifiable(warnings),
    );
  }

  Future<String> _sha256(File file) async =>
      sha256.convert(await file.readAsBytes()).toString();

  Future<Map<String, String>> _checksums(Directory directory) async {
    if (!await directory.exists()) return const {};
    final entries = <File>[];
    await for (final entity in directory.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is File) entries.add(entity);
    }
    entries.sort((a, b) => a.path.compareTo(b.path));
    return {
      for (final file in entries)
        p.relative(file.path, from: directory.path).replaceAll('\\', '/'):
            await _sha256(file),
    };
  }
}
