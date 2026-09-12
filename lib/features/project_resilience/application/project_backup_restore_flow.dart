import 'dart:io';

import 'package:path/path.dart' as p;

import '../../../database/project/project_database.dart';
import 'project_backup_restore_preview.dart';
import 'project_resilience_controller.dart';
import 'project_session_manager.dart';

/// Orchestrates a user-controlled backup restore against a live project
/// session (Step 145.34). Replacing project.db under an open session is a
/// corruption hazard, so the active session is closed first, the snapshot is
/// restored over the package files, and the same project is reopened
/// afterwards; the shell then re-renders from the restored snapshot instead
/// of holding stale database state.
///
/// A backup whose database schema is NEWER than the application schema is
/// rejected before the session is closed or any live file is touched, so the
/// shell never loses its session to a restore that could not succeed.
///
/// The close/reopen steps are injected as callbacks so this flow stays free
/// of provider imports; the UI wires them to the project session controller.
class ProjectBackupRestoreFlow {
  const ProjectBackupRestoreFlow._();

  static Future<void> restoreBackupAndReopen({
    required Future<void> Function() closeActiveSession,
    required Future<void> Function() reopenProject,
    required ProjectSession session,
    required ProjectBackup backup,
  }) async {
    final preview = await ProjectBackupRestorePreview.compute(
      package: session.package,
      backup: _backupDirectory(session, backup),
    );
    if (preview.compatibility == RestoreCompatibility.blocked) {
      throw StateError(
        'Backup ${preview.backupId} cannot be restored: schema '
        '${preview.backupSchemaVersion} is newer than application schema '
        '${preview.currentSchemaVersion}.',
      );
    }
    await closeActiveSession();
    await ProjectResilienceController(session).restoreBackup(backup);
    await reopenProject();
  }

  static Directory _backupDirectory(
    ProjectSession session,
    ProjectBackup backup,
  ) {
    final stored = backup.relativePath;
    if (p.isAbsolute(stored)) return Directory(stored);
    return Directory(session.package.resolve(stored));
  }
}
