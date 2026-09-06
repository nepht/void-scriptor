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
    }
    return preferred;
  }
}
