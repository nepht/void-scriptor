import 'workflow_definition.dart';
import 'workflow_validation.dart';

/// Sprint 103 / 103.23 — versioned workflow template registry.
///
/// Templates are validated AT REGISTRATION; instantiation produces a fresh
/// definition bound to a new execution id. Untrusted template content is
/// never auto-executed.

class WorkflowTemplateInvalid implements Exception {
  WorkflowTemplateInvalid(this.issues);

  final List<WorkflowValidationIssue> issues;

  @override
  String toString() =>
      'WorkflowTemplateInvalid: ${issues.map((i) => i.code).join(', ')}';
}

class WorkflowTemplateConflict implements Exception {
  WorkflowTemplateConflict(this.templateId, this.version);

  final String templateId;
  final int version;

  @override
  String toString() =>
      'WorkflowTemplateConflict: $templateId v$version already registered';
}

class WorkflowTemplateNotFound implements Exception {
  WorkflowTemplateNotFound(this.templateId);

  final String templateId;

  @override
  String toString() => 'WorkflowTemplateNotFound: $templateId';
}

class WorkflowTemplateRegistry {
  WorkflowTemplateRegistry({required this.validationService});

  final WorkflowValidationService validationService;
  final Map<String, WorkflowDefinition> _templates = {};

  String _key(String id, int version) => '$id@$version';

  void register(WorkflowDefinition template) {
    final issues = validationService.validate(template);
    if (issues.isNotEmpty) {
      throw WorkflowTemplateInvalid(issues);
    }
    final key = _key(template.workflowId, template.version);
    if (_templates.containsKey(key)) {
      throw WorkflowTemplateConflict(template.workflowId, template.version);
    }
    _templates[key] = template;
  }

  /// Instantiates the template under a NEW execution identity: the stored
  /// template itself stays immutable for future instantiations.
  WorkflowDefinition instantiate({
    required String templateId,
    required String newExecutionId,
    int version = 1,
  }) {
    final template = _templates[_key(templateId, version)];
    if (template == null) {
      throw WorkflowTemplateNotFound(templateId);
    }
    final now = DateTime.now().toUtc();
    return WorkflowDefinition(
      workflowId: newExecutionId,
      name: template.name,
      version: template.version,
      steps: template.steps,
      inputs: template.inputs,
      outputs: template.outputs,
      policy: template.policy,
      createdAt: now,
      updatedAt: now,
    );
  }

  List<String> get templateIds => _templates.keys.toList()..sort();
}
