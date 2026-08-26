import 'dart:io';

import 'package:void_scriptor/core/project_package/project_package.dart';

import '../application/novel_character_link_repository.dart';
import '../application/workspace_export_service.dart';
import 'workspace_export_options_dialog.dart';

/// Binds an explicitly chosen export option set to the export service.
///
/// Screens call this instead of touching [WorkspaceExportService] directly so
/// the ADR-WS-001 representation decision cannot be bypassed or silently
/// defaulted.
class WorkspaceExportActions {
  const WorkspaceExportActions({required this.package, required this.links});

  final ProjectPackage package;
  final NovelCharacterLinkRepository links;

  Future<File> run(
    String novelWorkspaceId,
    WorkspaceExportOptions options, {
    required Directory destination,
  }) {
    return WorkspaceExportService(package: package, links: links).exportNovel(
      novelWorkspaceId,
      destination: destination,
      characterRepresentation: options.characterRepresentation,
    );
  }
}
