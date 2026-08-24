import 'package:flutter/material.dart';

import 'package:void_scriptor/workflow/workflow_definition.dart';
import 'package:void_scriptor/workflow/workflow_validation.dart';

/// Sprint 103 / 103.25 — Workflow Editor UI (alpha scope).
///
/// Edits the canonical fields as text; validates live via
/// [WorkflowValidationService] and reports issues without ever executing.

class WorkflowEditorScreen extends StatefulWidget {
  const WorkflowEditorScreen({
    required this.validationService,
    this.defaultCommandType = 'manual.noop',
    this.initial,
    this.onSave,
    super.key,
  });

  final WorkflowValidationService validationService;

  /// Command assigned to newly authored steps; must be a registered
  /// command in the injected [validationService] for drafts to validate.
  final String defaultCommandType;
  final WorkflowDefinition? initial;
  final void Function(WorkflowDefinition saved)? onSave;

  @override
  State<WorkflowEditorScreen> createState() => _WorkflowEditorScreenState();
}

class _WorkflowEditorScreenState extends State<WorkflowEditorScreen> {
  late final TextEditingController _id = TextEditingController(
    text: widget.initial?.workflowId ?? '',
  );
  late final TextEditingController _name = TextEditingController(
    text: widget.initial?.name ?? '',
  );
  late final TextEditingController _steps = TextEditingController(
    text: (widget.initial?.steps ?? const []).map((s) => s.stepId).join(', '),
  );
  List<WorkflowValidationIssue> _issues = const [];

  void _validate() {
    final draft = _draft();
    setState(() {
      _issues = draft == null
          ? const []
          : widget.validationService.validate(draft);
    });
  }

  WorkflowDefinition? _draft() {
    final stepIds = _steps.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (_id.text.trim().isEmpty || stepIds.isEmpty) return null;
    final now = DateTime.now().toUtc();
    return WorkflowDefinition(
      workflowId: _id.text.trim(),
      name: _name.text.trim(),
      version: (widget.initial?.version ?? 0) + 1,
      steps: [
        for (final sid in stepIds)
          WorkflowStep(stepId: sid, commandType: widget.defaultCommandType),
      ],
      policy: const WorkflowPolicy(allowedCapabilities: {}),
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Workflow Editor')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              key: const Key('editor-id'),
              controller: _id,
              decoration: const InputDecoration(labelText: 'Workflow ID'),
              onChanged: (_) => _validate(),
            ),
            TextField(
              key: const Key('editor-name'),
              controller: _name,
              decoration: const InputDecoration(labelText: 'Name'),
              onChanged: (_) => _validate(),
            ),
            TextField(
              key: const Key('editor-steps'),
              controller: _steps,
              decoration: const InputDecoration(
                labelText: 'Steps (comma-separated ids)',
              ),
              onChanged: (_) => _validate(),
            ),
            const SizedBox(height: 12),
            if (_issues.isNotEmpty)
              Text(
                'Validation issues:',
                key: const Key('editor-issues'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              )
            else if (_draft() == null)
              const Text('Incomplete draft: add an ID and at least one step.')
            else ...[
              const Text('Valid so far.'),
              const SizedBox(height: 8),
              FilledButton(
                key: const Key('editor-save'),
                onPressed: () {
                  final draft = _draft();
                  if (draft != null) widget.onSave?.call(draft);
                },
                child: const Text('Save'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
