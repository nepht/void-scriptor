import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/typography/void_typography.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

import '../../character/presentation/character_controller.dart';
import '../../character/presentation/character_workspace_controller.dart';
import '../../character/presentation/widgets/character_deletion_review_dialog.dart';
import '../../projects/presentation/project_persistence_providers.dart';
import '../application/workspace_section_controller.dart';

/// Workspace chrome header: module context, project name, character identity,
/// and the character action cluster (Favorite / History / Delete).
///
/// The character feature seam lives here deliberately: the workspace chrome
/// renders character context, but `WorkspacePanel` stays character-free so
/// header changes do not ripple into the workspace shell.
class WorkspaceHeader extends ConsumerWidget {
  const WorkspaceHeader({
    super.key,
    required this.kind,
    required this.icon,
    required this.title,
    this.projectName,
    this.characterId,
  });

  final WorkspaceKind kind;
  final IconData icon;
  final String title;
  final String? projectName;
  final String? characterId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final character = characterId == null
        ? null
        : ref.watch(characterWorkspaceProvider(characterId!)).valueOrNull;
    final session = ref.watch(projectSessionProvider).valueOrNull;
    final resolvedProjectName = projectName?.trim();
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: context.palette.panelSecondary,
        border: Border(bottom: BorderSide(color: context.palette.borderSoft)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: context.palette.primaryBright),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    kind == WorkspaceKind.character ? 'Character' : title,
                    style: VoidTypography.breadcrumb.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.palette.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (kind == WorkspaceKind.character && character != null) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(Icons.chevron_right, size: 15),
                  ),
                  Flexible(
                    child: Text(
                      character.displayName,
                      style: VoidTypography.breadcrumb,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (resolvedProjectName != null &&
              resolvedProjectName.isNotEmpty &&
              kind != WorkspaceKind.character)
            Flexible(
              child: Text(
                resolvedProjectName,
                style: VoidTypography.breadcrumb,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          if (kind == WorkspaceKind.character) ...[
            IconButton(
              tooltip: 'Favorite',
              visualDensity: VisualDensity.compact,
              onPressed: () => _feedback(
                context,
                'Favorite is available in the next metadata slice.',
              ),
              icon: const Icon(Icons.star_border, size: 17),
            ),
            IconButton(
              tooltip: 'History',
              visualDensity: VisualDensity.compact,
              onPressed: () =>
                  _feedback(context, 'Character history is not persisted yet.'),
              icon: const Icon(Icons.history, size: 17),
            ),
            IconButton(
              tooltip: 'Delete',
              visualDensity: VisualDensity.compact,
              onPressed: character == null || session == null
                  ? null
                  : () async {
                      final actions = CharacterActions(
                        ref,
                        character.projectId,
                        session.database,
                      );
                      final decision = await showCharacterDeletionReviewDialog(
                        context: context,
                        loadReview: () =>
                            actions.reviewDeletion(character.assetId),
                      );
                      if (decision != null) {
                        await actions.delete(
                          character.assetId,
                          decision: decision,
                        );
                      }
                    },
              icon: const Icon(Icons.delete_outline, size: 17),
            ),
          ],
        ],
      ),
    );
  }

  void _feedback(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
