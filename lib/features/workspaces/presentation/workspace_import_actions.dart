import 'dart:io';

import 'package:void_scriptor/core/project_package/project_package.dart';

import '../application/novel_character_link_repository.dart';
import '../application/workspace_import_service.dart';
import 'workspace_import_options_dialog.dart';

/// Binds an explicitly chosen import option set to the import service and
/// exposes the archive-declared character representation so screens can show
/// it (via the options dialog) before any mutation happens.
class WorkspaceImportActions {
  const WorkspaceImportActions({required this.package, required this.links});

  final ProjectPackage package;
  final NovelCharacterLinkRepository links;

  /// Reads `characterRepresentation` from the archive manifest without
  /// touching the target workspace. Returns null when the archive does not
  /// declare one.
  Future<String?> peekCharacterRepresentation(File archive) async {
    final manifest = await WorkspaceImportService.peekManifest(archive);
    return manifest['characterRepresentation'] as String?;
  }

  Future<WorkspaceRestoreResult> run(
    File archive,
    WorkspaceImportOptions options, {
    String? expectedWorkspaceId,
  }) {
    return WorkspaceImportService(package: package, links: links).restoreNovel(
      archive,
      expectedWorkspaceId: expectedWorkspaceId,
      collisionChoice: options.collisionChoice,
    );
  }
}
