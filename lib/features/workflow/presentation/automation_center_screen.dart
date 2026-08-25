import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../automation/automation_rule.dart';
import '../../../automation/workflow_trigger.dart';

/// Sprint 104 / 104.30 — Automation Center: rules overview + live
/// metrics snapshot (identifier-only) in a responsive single column.

class AutomationCenterScreen extends StatelessWidget {
  const AutomationCenterScreen({
    required this.rules,
    required this.metricsSnapshot,
    super.key,
  });

  final List<AutomationRule> rules;
  final Map<String, Object> metricsSnapshot;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        key: const Key('automation-center'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Automation Center',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          if (rules.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('No automation rules yet.'),
            )
          else
            for (final rule in rules)
              ListTile(
                key: Key('rule-${rule.ruleId}'),
                leading: Icon(_iconFor(rule.trigger.type)),
                title: Text(rule.ruleId),
                subtitle: Text('workflow ${rule.workflowId}'),
                trailing: Switch(
                  value: rule.enabled,
                  onChanged: null, // alpha scope: display-only toggle
                ),
              ),
          const SizedBox(height: 12),
          _MetricsPanel(snapshot: metricsSnapshot),
        ],
      ),
    );
  }

  IconData _iconFor(WorkflowTriggerType type) => switch (type) {
    WorkflowTriggerType.manual => Icons.touch_app,
    WorkflowTriggerType.schedule => Icons.schedule,
    WorkflowTriggerType.projectEvent => Icons.folder_open,
    WorkflowTriggerType.assetEvent => Icons.image,
    WorkflowTriggerType.jobEvent => Icons.work_outline,
    WorkflowTriggerType.pluginEvent => Icons.extension,
  };
}

class _MetricsPanel extends StatelessWidget {
  const _MetricsPanel({required this.snapshot});

  final Map<String, Object> snapshot;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('metrics-panel'),
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Wrap(
        spacing: 24,
        runSpacing: 8,
        children: [
          for (final entry in snapshot.entries)
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.key, style: Theme.of(context).textTheme.labelSmall),
                Text(
                  '${entry.value}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// 104.31 — Rule editor (minimal but honest): workflow id + save gate.

class RuleEditorScreen extends StatefulWidget {
  const RuleEditorScreen({
    required this.validatorRules,
    required this.onSave,
    super.key,
  });

  /// Allowed condition fields per the trigger schema (104.7 contract).
  final Map<String, bool> validatorRules;
  final ValueChanged<AutomationRule> onSave;

  @override
  State<RuleEditorScreen> createState() => _RuleEditorScreenState();
}

class _RuleEditorScreenState extends State<RuleEditorScreen> {
  final _workflowController = TextEditingController();

  @override
  void dispose() {
    _workflowController.dispose();
    super.dispose();
  }

  bool get _draftComplete =>
      _workflowController.text.trim().isNotEmpty &&
      widget.validatorRules.values.every((ok) => ok);

  AutomationRule get _draft => AutomationRule(
    ruleId: 'r-${DateTime.now().millisecondsSinceEpoch}',
    trigger: WorkflowTrigger(
      triggerId: 't-editor',
      type: WorkflowTriggerType.projectEvent,
      configuration: const {},
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
    ),
    conditions: const [],
    workflowId: _workflowController.text.trim(),
  );

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const Key('rule-editor'),
      padding: const EdgeInsets.all(12),
      children: [
        TextField(
          key: const Key('editor-workflow'),
          controller: _workflowController,
          decoration: const InputDecoration(labelText: 'Workflow ID'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        if (_draftComplete)
          FilledButton(
            key: const Key('editor-save'),
            onPressed: () => widget.onSave(_draft),
            child: const Text('Save rule'),
          ),
      ],
    );
  }
}

// 104.32 — Automation templates: curated starting points.

class AutomationTemplatesScreen extends StatelessWidget {
  const AutomationTemplatesScreen({required this.onInstantiate, super.key});

  static const List<(String, WorkflowTriggerType, String)> _templates = [
    ('Export after job completes', WorkflowTriggerType.jobEvent, 'wf-export'),
    ('Backup at startup', WorkflowTriggerType.projectEvent, 'wf-backup'),
    (
      'Thumbnail pipeline on import',
      WorkflowTriggerType.assetEvent,
      'wf-thumbnails',
    ),
  ];

  final ValueChanged<AutomationRule> onInstantiate;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      key: const Key('template-list'),
      itemCount: _templates.length,
      itemBuilder: (context, index) {
        final (title, type, workflowId) = _templates[index];
        return ListTile(
          key: Key('template-instantiate-$index'),
          leading: const Icon(Icons.auto_awesome),
          title: Text(title),
          subtitle: Text('creates workflow $workflowId'),
          onTap: () => onInstantiate(
            AutomationRule(
              ruleId: 'tpl-$index-${DateTime.now().millisecondsSinceEpoch}',
              trigger: WorkflowTrigger(
                triggerId: 't-tpl-$index',
                type: type,
                configuration: const {},
                createdAt: DateTime.now().toUtc(),
                updatedAt: DateTime.now().toUtc(),
              ),
              conditions: const [],
              workflowId: workflowId,
            ),
          ),
        );
      },
    );
  }
}

// 104.33 — Import & export (pure functions; UI-agnostic by design).

String exportRules(List<AutomationRule> rules) {
  final payload = rules
      .map(
        (r) => {
          'ruleId': r.ruleId,
          'workflowId': r.workflowId,
          'enabled': r.enabled,
          'triggerType': r.trigger.type.name,
        },
      )
      .toList();
  return jsonEncode(payload);
}

List<AutomationRule> importRules(String jsonText) {
  final decoded = jsonDecode(jsonText);
  if (decoded is! List) throw ArgumentError('expected a JSON array of rules');
  return decoded.map((raw) {
    if (raw is! Map<String, dynamic>) {
      throw ArgumentError('each rule must be a JSON object');
    }
    // Fail closed on secret-shaped payloads — never ingest them.
    raw.forEach((key, value) {
      if (key.toLowerCase().contains('secret')) {
        throw ArgumentError('refusing payload with secret-shaped key');
      }
    });
    final triggerType = WorkflowTriggerType.values.firstWhere(
      (t) => t.name == raw['triggerType'],
      orElse: () => WorkflowTriggerType.manual,
    );
    final now = DateTime.now().toUtc();
    return AutomationRule(
      ruleId: raw['ruleId'] as String,
      trigger: WorkflowTrigger(
        triggerId: 'imported',
        type: triggerType,
        configuration: const {},
        createdAt: now,
        updatedAt: now,
      ),
      conditions: const [],
      workflowId: raw['workflowId'] as String,
      enabled: raw['enabled'] as bool? ?? false,
    );
  }).toList();
}
