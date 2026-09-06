import 'dart:io';

import 'package:path/path.dart' as p;

import '../../../core/project_package/project_package.dart';

/// Backup destination policy for local backups (Step 145.34:
/// configurable location acceptance).
///
/// Default behavior is unchanged: backups land in the package-internal
/// `backups/` directory. When a custom backup root is configured AND the
/// location exists on disk (removable drive present), new backups are
/// written there instead. The policy is deliberately fail-safe: a missing
/// custom location (USB unplugged, folder removed) never blocks or loses a
/// backup; creation falls back to the internal default so the most recent
/// backup always exists somewhere safe.
class BackupLocationPolicy {
  BackupLocationPolicy({this.customBackupRoot});

  /// Optional user-selected backup root (e.g. `D:\VoidScriptorBackups`
  /// or a USB drive). `null` keeps the package-internal default.
  Directory? customBackupRoot;

  /// Attaches (or clears with `null`) the custom backup root at runtime.
  void configureCustomBackupRoot(Directory? root) {
    customBackupRoot = root;
  }

  /// Root that should receive the next backup for [package].
  Directory resolveBackupRoot(ProjectPackage package) {
    final custom = customBackupRoot;
    if (custom != null && custom.existsSync()) return custom;
    return package.backupDirectory;
  }

  /// Whether [backupPath] was written outside the package (custom root).
  static bool isExternalBackup(ProjectPackage package, String backupPath) {
    final absolute = p.normalize(p.absolute(backupPath));
    final root = p.normalize(p.absolute(package.root.path));
    return !(p.isWithin(root, absolute) || absolute == root);
  }
}
