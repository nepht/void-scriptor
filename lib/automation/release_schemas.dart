/// Silent edits are forbidden; bumping requires a migration story.
library;

class ReleaseSchemas {
  ReleaseSchemas._();

  /// First frozen generation of the workflow/automation surface.
  static const int workflowSchema = 1;
  static const int automationRuleSchema = 1;
  static const int triggerSchema = 1;
  static const int executionRecordSchema = 1;

  /// Identifier-only record suitable for manifests and diagnostics.
  static Map<String, int> record() => const {
    'workflow_schema': workflowSchema,
    'automation_rule_schema': automationRuleSchema,
    'trigger_schema': triggerSchema,
    'execution_record_schema': executionRecordSchema,
  };
}
