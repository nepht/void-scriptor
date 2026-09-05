import 'dart:io';

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
}
