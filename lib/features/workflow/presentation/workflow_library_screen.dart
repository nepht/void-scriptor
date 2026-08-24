import 'package:flutter/material.dart';

import 'package:void_scriptor/workflow/workflow_definition.dart';
import 'package:void_scriptor/workflow/workflow_templates.dart';

/// Sprint 103 / 103.24 — Workflow Library UI.
///
/// Lists registered templates; instantiating a template emits the new
/// execution identity via [onInstantiate]. Read-only over the registry —
/// this screen never executes anything itself.

class WorkflowLibraryScreen extends StatelessWidget {
  const WorkflowLibraryScreen({
    required this.registry,
    this.onInstantiate,
    super.key,
  });

  final WorkflowTemplateRegistry registry;
  final void Function(WorkflowDefinition instantiated)? onInstantiate;

  @override
  Widget build(BuildContext context) {
    final ids = registry.templateIds;
    return Scaffold(
      appBar: AppBar(title: const Text('Workflow Library')),
      body: ids.isEmpty
          ? const Center(child: Text('No templates registered'))
          : ListView.builder(
              itemCount: ids.length,
              itemBuilder: (context, index) {
                final key = ids[index];
                return ListTile(
                  key: ValueKey('tpl-$key'),
                  leading: const Icon(Icons.account_tree_outlined),
                  title: Text(key),
                  trailing: IconButton(
                    key: ValueKey('run-$key'),
                    icon: const Icon(Icons.play_arrow),
                    tooltip: 'Instantiate & run',
                    onPressed: () {
                      final dot = key.lastIndexOf('@');
                      final id = key.substring(0, dot);
                      final version = int.parse(key.substring(dot + 1));
                      final instance = registry.instantiate(
                        templateId: id,
                        version: version,
                        newExecutionId:
                            'exec-${DateTime.now().microsecondsSinceEpoch}',
                      );
                      onInstantiate?.call(instance);
                    },
                  ),
                );
              },
            ),
    );
  }
}
