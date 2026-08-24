import 'workflow_definition.dart';
import 'workflow_execution.dart';

/// Sprint 103 / 103.6 — reject invalid workflows before execution.
///
/// Canonical rules: unique_step_ids, known_commands, valid_bindings,
/// acyclic_dependencies (+ unknown_dependency), permission_compatibility.

class WorkflowValidationIssue {
  const WorkflowValidationIssue({
    required this.code,
    required this.message,
    this.stepId,
  });

  final String code;
  final String message;
  final String? stepId;

  @override
  String toString() => '[$code]${stepId == null ? '' : ' @$stepId'} $message';
}

class WorkflowValidationService {
  WorkflowValidationService({
    this.knownCommands = const {},
    this.commandCapabilities = const {},
  });

  /// Commands registered in the app's command registry.
  final Set<String> knownCommands;

  /// Capabilities each command requires (empty = capability-free commands).
  final Map<String, Set<String>> commandCapabilities;

  List<WorkflowValidationIssue> validate(WorkflowDefinition workflow) {
    final issues = <WorkflowValidationIssue>[];
    final seenIds = <String>{};

    for (final step in workflow.steps) {
      // unique_step_ids
      if (!seenIds.add(step.stepId)) {
        issues.add(
          WorkflowValidationIssue(
            code: 'unique_step_ids',
            stepId: step.stepId,
            message: 'duplicate step id "${step.stepId}"',
          ),
        );
      }

      // known_commands
      if (!knownCommands.contains(step.commandType)) {
        issues.add(
          WorkflowValidationIssue(
            code: 'known_commands',
            stepId: step.stepId,
            message: 'unknown command "${step.commandType}"',
          ),
        );
      }

      // permission_compatibility — command needs must fit workflow policy.
      final needed = commandCapabilities[step.commandType];
      if (needed != null &&
          !needed.every(workflow.policy.allowedCapabilities.contains)) {
        issues.add(
          WorkflowValidationIssue(
            code: 'permission_compatibility',
            stepId: step.stepId,
            message:
                '"${step.commandType}" requires $needed beyond policy '
                '${workflow.policy.allowedCapabilities}',
          ),
        );
      }

      // valid_bindings — inputs resolve to declared sources only.
      final earlierIds = seenIds.toList(); // ids declared before this step
      for (final b in step.inputBindings) {
        final okIn =
            b.reference.startsWith('in.') &&
            workflow.inputs.contains(b.reference.substring(3));
        final okStep =
            b.reference.startsWith('step.') &&
            earlierIds.any(
              (id) =>
                  b.reference == 'step.$id' ||
                  b.reference.startsWith('step.$id.'),
            );
        if (!okIn && !okStep) {
          issues.add(
            WorkflowValidationIssue(
              code: 'valid_bindings',
              stepId: step.stepId,
              message:
                  'input "${b.name}" references undeclared source "${b.reference}"',
            ),
          );
        }
      }
    }

    // Graph soundness delegated to the resolver (single implementation).
    try {
      WorkflowDependencyResolver().plan(workflow);
    } on WorkflowCycleException catch (e) {
      issues.add(
        WorkflowValidationIssue(
          code: 'acyclic_dependencies',
          message: e.toString(),
        ),
      );
    } on UnknownStepReference catch (e) {
      issues.add(
        WorkflowValidationIssue(
          code: 'unknown_dependency',
          stepId: e.stepId,
          message: e.toString(),
        ),
      );
    }

    return issues;
  }
}
