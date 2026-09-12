import 'dart:io';

import 'package:void_scriptor/core/project_package/project_package.dart';

import '../application/novel_character_link_repository.dart';
import '../application/workspace_import_service.dart';
import 'workspace_import_options_dialog.dart';

/// Binds an explicitly chosen import option set to the import service and
/// exposes the archive-declared character representation so screens can show
/// it (via the options dialog) before any mutation happens.
class WorkspaceImportActions {
  const WorkspaceImportActions({
    required this.package,
    required this.links,
    this.maxArchiveBytes = WorkspaceImportService.defaultMaxArchiveBytes,
  });

  final ProjectPackage package;
  final NovelCharacterLinkRepository links;

  /// vs-hunt-20260912n BUG-12: the same size cap the service enforces,
  /// applied to the peek/preflight read as well.
  final int maxArchiveBytes;

  /// Reads `characterRepresentation` from the archive manifest without
  /// touching the target workspace. Returns null when the archive does not
  /// declare one.
  ///
  /// vs-hunt-20260912n BUG-10: delegates to [preflightArchive] so screens
  /// that keep the snapshot can hand it to [run] and the archive is decoded
  /// exactly once; callers that discard it pay at most the same single decode
  /// they paid before.
  Future<String?> peekCharacterRepresentation(File archive) async {
    final preflight = await preflightArchive(archive);
    return preflight.characterRepresentation;
  }

  /// vs-hunt-20260912n BUG-10: decodes the archive ONCE (bounded by the
  /// import service's size cap) and returns the snapshot the options dialog
  /// and the restore both consume.
  Future<WorkspaceArchivePreflight> preflightArchive(File archive) {
    return WorkspaceImportService.preflightArchive(
      archive,
      maxArchiveBytes: maxArchiveBytes,
    );
  }

  Future<WorkspaceRestoreResult> run(
    File archive,
    WorkspaceImportOptions options, {
    String? expectedWorkspaceId,
    WorkspaceArchivePreflight? preflight,
  }) {
    return WorkspaceImportService(
      package: package,
      links: links,
      maxArchiveBytes: maxArchiveBytes,
    ).restoreNovel(
      archive,
      expectedWorkspaceId: expectedWorkspaceId,
      collisionChoice: options.collisionChoice,
      preflight: preflight,
    );
  }
}
