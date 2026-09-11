import 'dart:io';

import 'package:path/path.dart' as p;

import 'project_recovery_service.dart';

/// Keeps the machine-specific storage pointer outside Documents/project data.
///
/// This prevents a broken cloud-synced Documents folder from blocking the app
/// from remembering a healthy custom project location on another drive.
class StorageLocationRegistryResolver {
  const StorageLocationRegistryResolver();

  static const fileName = 'storage_locations.json';

  Future<File> resolve({
    required Directory applicationSupportDirectory,
    required File legacyFile,
  }) async {
    final preferred = File(
      p.join(applicationSupportDirectory.path, 'VoidScriptor', fileName),
    );
    await const ProjectRecoveryService().recoverIfInterrupted(preferred);
    if (await preferred.exists()) return preferred;

    if (await legacyFile.exists()) {
      await const ProjectRecoveryService().atomicWrite(
        target: preferred,
        content: await legacyFile.readAsString(),
      );
      // BUG-23 (bug-hunt run197, Referee REAL BUG): consume the legacy source
      // after a successful copy. A one-way copy that leaves the source in
      // place lets stale legacy content resurrect over newer durable state if
      // the preferred file is ever lost. Rename (not delete) keeps the content
      // available for inspection; failure to rename must not fail the
      // migration, so this is best-effort only.
      try {
        await legacyFile.rename(
          p.join(legacyFile.parent.path, '$fileName.imported'),
        );
      } on FileSystemException {
        // Best-effort consumption: a leftover legacy file reproduces the old
        // one-way-copy behavior, not a data hazard beyond the filed finding.
      }
    }
    return preferred;
  }
}
