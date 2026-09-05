import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'project_manifest.dart';

class ProjectRecoveryService {
  const ProjectRecoveryService();

  Future<void> atomicWrite({
    required File target,
    required String content,
  }) async {
    await target.parent.create(recursive: true);
    final temporary = File('${target.path}.tmp');
    final backup = File('${target.path}.bak');

    await temporary.writeAsString(content, flush: true);
    if (await target.exists()) {
      if (await backup.exists()) await backup.delete();
      await target.rename(backup.path);
    }

    try {
      await temporary.rename(target.path);
    } catch (_) {
      if (await backup.exists() && !await target.exists()) {
        await backup.rename(target.path);
      }
      rethrow;
    }
  }

  /// Recovers a target left behind by an interrupted [atomicWrite].
  ///
  /// A process crash (power loss, kill, permission failure) between the
  /// `target -> .bak` rename and the `.tmp -> target` rename leaves the
  /// target missing while `.bak` (last durable content) and `.tmp` (new
  /// content, possibly truncated) still exist. The `.tmp` file is never
  /// trusted because it was never renamed into place; restoring `.bak`
  /// preserves the caller's previous durable state instead of silently
  /// reporting the record missing.
  Future<void> recoverIfInterrupted(File target) async {
    if (await target.exists()) return;
    final backup = File('${target.path}.bak');
    if (await backup.exists()) {
      await backup.rename(target.path);
    }
  }

  Future<bool> restoreBackup(File target) async {
    final backup = File('${target.path}.bak');
    if (!await backup.exists()) return false;
    if (await target.exists()) await target.delete();
    await backup.rename(target.path);
    return true;
  }

  /// Recovers the destination-collision stash of an interrupted import.
  ///
  /// [PortableProjectImportCoordinator] renames an existing
  /// `<projectId>.voidproject` package into a hidden
  /// `.<projectId>.voidproject.import-backup-<uuid>` stash before an import
  /// reuses that project ID. A process death inside that window (kill /
  /// power loss) never runs the Dart rollback: the user's original package
  /// stays buried under the stash while the registry still points at the
  /// final path. For every stash in [ownerDirectory] whose canonical
  /// package directory no longer exists, this restores the stash to
  /// `<projectId>.voidproject`. When the canonical directory exists again
  /// (the import had already completed) the stash is left untouched:
  /// recovery must not guess between two complete copies. Returns the
  /// number of restored packages.
  Future<int> recoverInterruptedImportStashes(Directory ownerDirectory) async {
    if (!await ownerDirectory.exists()) return 0;
    final stashes = <Directory>[];
    await for (final entity in ownerDirectory.list(followLinks: false)) {
      if (entity is! Directory) continue;
      final name = p.basename(entity.path);
      if (!name.startsWith('.') ||
          !name.contains('.voidproject.import-backup-')) {
        continue;
      }
      stashes.add(entity);
    }
    var restored = 0;
    for (final stash in stashes) {
      final manifestFile = File(
        p.join(stash.path, 'manifest', 'project.json'),
      );
      if (!await manifestFile.exists()) continue;
      final Object? decoded;
      try {
        decoded = jsonDecode(await manifestFile.readAsString());
      } on Object {
        continue;
      }
      if (decoded is! Map<String, dynamic>) continue;
      final ProjectManifest manifest;
      try {
        manifest = ProjectManifest.fromJson(decoded);
      } on Object {
        continue;
      }
      final canonical = Directory(
        p.join(ownerDirectory.path, '${manifest.id}.voidproject'),
      );
      if (await canonical.exists()) continue;
      await stash.rename(canonical.path);
      restored++;
    }
    return restored;
  }
}
