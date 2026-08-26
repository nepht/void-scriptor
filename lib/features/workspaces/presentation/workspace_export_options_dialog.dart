import 'package:flutter/material.dart';

import 'package:void_scriptor/features/workspaces/application/workspace_export_service.dart';

/// Explicitly chosen export options.
///
/// [characterRepresentation] has no implicit default here: ADR-WS-001
/// requires the portable export to DECLARE its representation, so the value
/// recorded is always the one the user consciously picked.
class WorkspaceExportOptions {
  const WorkspaceExportOptions({required this.characterRepresentation});

  final WorkspaceCharacterRepresentation characterRepresentation;
}

/// Shows the Novel workspace export options dialog.
///
/// Completes with [WorkspaceExportOptions] after an explicit representation
/// choice plus confirmation, or null when cancelled. The confirm action stays
/// disabled until a representation is selected — an export must never claim a
/// representation nobody chose.
Future<WorkspaceExportOptions?> showWorkspaceExportOptionsDialog({
  required BuildContext context,
}) {
  return showDialog<WorkspaceExportOptions>(
    context: context,
    builder: (_) => const WorkspaceExportOptionsDialog(),
  );
}

class WorkspaceExportOptionsDialog extends StatefulWidget {
  const WorkspaceExportOptionsDialog({super.key});

  @override
  State<WorkspaceExportOptionsDialog> createState() =>
      _WorkspaceExportOptionsDialogState();
}

class _WorkspaceExportOptionsDialogState
    extends State<WorkspaceExportOptionsDialog> {
  /// Null until the user picks a representation; keeps Export disabled.
  WorkspaceCharacterRepresentation? _chosen;

  static const _choices = <(WorkspaceCharacterRepresentation, String, String)>[
    (
      WorkspaceCharacterRepresentation.referenceManifest,
      'Reference manifest',
      'Archive links only; characters stay in their canonical project.',
    ),
    (
      WorkspaceCharacterRepresentation.embeddedSnapshot,
      'Embedded snapshot',
      'Copies linked characters into the archive as a snapshot.',
    ),
    (
      WorkspaceCharacterRepresentation.fork,
      'Fork',
      'Embeds characters as a diverging fork of the canonical ones.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Export novel workspace'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('How should linked characters be represented?'),
            RadioGroup<WorkspaceCharacterRepresentation>(
              groupValue: _chosen,
              onChanged: (value) => setState(() => _chosen = value),
              child: Column(
                children: _choices
                    .map(
                      (choice) =>
                          RadioListTile<WorkspaceCharacterRepresentation>(
                            key: ValueKey(choice.$1),
                            title: Text(choice.$2),
                            subtitle: Text(choice.$3),
                            value: choice.$1,
                          ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          // Locked until an explicit choice exists.
          onPressed: _chosen == null
              ? null
              : () => Navigator.of(context).pop(
                  WorkspaceExportOptions(characterRepresentation: _chosen!),
                ),
          child: const Text('Export'),
        ),
      ],
    );
  }
}
