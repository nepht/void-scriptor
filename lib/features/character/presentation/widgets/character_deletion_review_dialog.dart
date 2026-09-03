import 'package:flutter/material.dart';

import 'package:void_scriptor/features/workspaces/application/workspace_character_deletion_service.dart';

/// Shows the Character deletion review dialog.
///
/// The returned future completes with the explicitly chosen
/// [CharacterDeletionDecision], or null when the user cancelled without
/// deciding. Loading, error, and empty-link states are rendered honestly;
/// the confirm action stays disabled until an explicit choice exists — except
/// when the character has no Novel links at all, where unlinking nothing is
/// the only possible outcome and is selected automatically.
Future<CharacterDeletionDecision?> showCharacterDeletionReviewDialog({
  required BuildContext context,
  required Future<CharacterDeletionReview> Function() loadReview,
}) {
  return showDialog<CharacterDeletionDecision>(
    context: context,
    builder: (_) => CharacterDeletionReviewDialog(loadReview: loadReview),
  );
}

class CharacterDeletionReviewDialog extends StatefulWidget {
  const CharacterDeletionReviewDialog({super.key, required this.loadReview});

  final Future<CharacterDeletionReview> Function() loadReview;

  @override
  State<CharacterDeletionReviewDialog> createState() =>
      _CharacterDeletionReviewDialogState();
}

class _CharacterDeletionReviewDialogState
    extends State<CharacterDeletionReviewDialog> {
  late final Future<CharacterDeletionReview> _reviewFuture;

  /// Set once the user picks an explicit decision; stays null otherwise so
  /// the confirm action cannot fire without a recorded choice.
  CharacterDeletionDecision? _chosen;

  @override
  void initState() {
    super.initState();
    _reviewFuture = widget.loadReview();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CharacterDeletionReview>(
      future: _reviewFuture,
      builder: (context, snapshot) {
        final Widget content;
        CharacterDeletionDecision? effectiveDecision;

        if (snapshot.connectionState != ConnectionState.done) {
          content = const SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text('Reviewing linked novels…'),
              ],
            ),
          );
        } else if (snapshot.hasError) {
          content = const SizedBox(
            width: 320,
            child: Text('Failed to load deletion review.'),
          );
        } else if (snapshot.data!.affectedNovelWorkspaceIds.isEmpty) {
          effectiveDecision = CharacterDeletionDecision.unlink;
          content = const SizedBox(
            width: 320,
            child: Text(
              'This character has no Novel links. Nothing will be unlinked.',
            ),
          );
        } else {
          effectiveDecision = _chosen;
          content = _ReviewBody(
            review: snapshot.data!,
            chosen: _chosen,
            onSelect: (decision) => setState(() => _chosen = decision),
          );
        }

        return AlertDialog(
          title: const Text('Delete this Character?'),
          content: content,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: effectiveDecision == null
                  ? null
                  : () => Navigator.of(context).pop(effectiveDecision),
              child: const Text('Delete Character'),
            ),
          ],
        );
      },
    );
  }
}

class _ReviewBody extends StatelessWidget {
  const _ReviewBody({
    required this.review,
    required this.chosen,
    required this.onSelect,
  });

  final CharacterDeletionReview review;
  final CharacterDeletionDecision? chosen;
  final ValueChanged<CharacterDeletionDecision?> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 360,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Linked Novels that reference this character:'),
          const SizedBox(height: 8),
          for (final novelId in review.affectedNovelWorkspaceIds)
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 4),
              child: Text(novelId),
            ),
          const SizedBox(height: 8),
          RadioGroup<CharacterDeletionDecision>(
            groupValue: chosen,
            onChanged: onSelect,
            child: const RadioListTile<CharacterDeletionDecision>(
              value: CharacterDeletionDecision.unlink,
              title: Text('Unlink from all listed Novels (keep their content)'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}
