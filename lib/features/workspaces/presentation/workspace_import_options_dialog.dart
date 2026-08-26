import 'package:flutter/material.dart';

import 'package:void_scriptor/features/workspaces/application/workspace_import_service.dart';

/// Explicitly chosen import options.
class WorkspaceImportOptions {
  const WorkspaceImportOptions({required this.collisionChoice});

  final WorkspaceImportCollisionChoice collisionChoice;
}

/// Human label for an archive-declared `characterRepresentation` value.
/// Unknown or missing declarations render honestly instead of being coerced
/// to a default the archive never claimed.
String workspaceRepresentationLabel(String? manifestValue) {
  switch (manifestValue) {
    case 'reference_manifest':
      return 'Reference manifest';
    case 'embedded_snapshot':
      return 'Embedded snapshot';
    case 'fork':
      return 'Fork';
    default:
      return 'Not declared';
  }
}

/// Shows the Novel workspace import options dialog.
///
/// [loadRepresentation] reads the archive-declared character representation
/// before any mutation; loading and failure states are rendered honestly and
/// the confirm action stays disabled until an explicit collision choice is
/// made — mirroring the deletion review dialog contract.
Future<WorkspaceImportOptions?> showWorkspaceImportOptionsDialog({
  required BuildContext context,
  required Future<String?> Function() loadRepresentation,
}) {
  return showDialog<WorkspaceImportOptions>(
    context: context,
    builder: (_) =>
        WorkspaceImportOptionsDialog(loadRepresentation: loadRepresentation),
  );
}

class WorkspaceImportOptionsDialog extends StatefulWidget {
  const WorkspaceImportOptionsDialog({
    super.key,
    required this.loadRepresentation,
  });

  final Future<String?> Function() loadRepresentation;

  @override
  State<WorkspaceImportOptionsDialog> createState() =>
      _WorkspaceImportOptionsDialogState();
}

class _WorkspaceImportOptionsDialogState
    extends State<WorkspaceImportOptionsDialog> {
  late final Future<String?> _representationFuture;

  /// Null until the user picks a collision choice; keeps Import disabled.
  WorkspaceImportCollisionChoice? _chosen;

  static const _choices = <(WorkspaceImportCollisionChoice, String, String)>[
    (
      WorkspaceImportCollisionChoice.fail,
      'Fail',
      'Refuse the import when the target novel already exists.',
    ),
    (
      WorkspaceImportCollisionChoice.skip,
      'Skip',
      'Leave the existing novel completely untouched.',
    ),
    (
      WorkspaceImportCollisionChoice.adoptExistingLinks,
      'Adopt existing links',
      'Keep existing files and insert only missing link entries.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _representationFuture = widget.loadRepresentation();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Import novel workspace'),
      content: SizedBox(
        width: 360,
        child: FutureBuilder<String?>(
          future: _representationFuture,
          builder: (context, snapshot) {
            final Widget body;
            if (snapshot.connectionState != ConnectionState.done) {
              body = const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Reading archive…'),
                ],
              );
            } else if (snapshot.hasError) {
              body = const Text('Failed to read the archive.');
            } else {
              final label = workspaceRepresentationLabel(snapshot.data);
              body = Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Characters travel as:'),
                  Text(
                    label,
                    key: const ValueKey('representation-label'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  const Text('If the novel already exists:'),
                  RadioGroup<WorkspaceImportCollisionChoice>(
                    groupValue: _chosen,
                    onChanged: (value) => setState(() => _chosen = value),
                    child: Column(
                      children: _choices
                          .map(
                            (choice) =>
                                RadioListTile<WorkspaceImportCollisionChoice>(
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
              );
            }
            return SizedBox(width: 360, child: body);
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          // Locked until an explicit collision choice exists.
          onPressed: _chosen == null
              ? null
              : () => Navigator.of(
                  context,
                ).pop(WorkspaceImportOptions(collisionChoice: _chosen!)),
          child: const Text('Import'),
        ),
      ],
    );
  }
}
