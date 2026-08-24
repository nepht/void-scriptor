import 'dart:convert';
import 'dart:io';

import '../core/jobs/background_job.dart';
import 'workflow_definition.dart';
import 'workflow_execution.dart';
import 'workflow_runner.dart';

/// Sprint 103 / 103.16 — honest crash recovery over real checkpoints.
///
/// Recovery options are OFFERED, never auto-applied
/// (`trusted_execution_by_default=false` spirit of 103.23).

/// Sync accessors so recovery can run before any async machinery boots.
extension WorkflowCheckpointStoreSync on WorkflowCheckpointStore {
  WorkflowCheckpoint? readSync(String executionId) {
    final f = fileFor(executionId);
    if (!f.existsSync()) return null;
    final decoded = jsonDecode(f.readAsStringSync()) as Map<String, Object?>;
    return WorkflowCheckpoint.fromJson(decoded);
  }

  List<WorkflowCheckpoint> listAllSync() {
    if (!directory.existsSync()) return const [];
    final files =
        directory
            .listSync()
            .whereType<File>()
            .where((f) => f.path.contains('workflow-checkpoint-'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    final out = <WorkflowCheckpoint>[];
    for (final f in files) {
      try {
        out.add(
          WorkflowCheckpoint.fromJson(
            jsonDecode(f.readAsStringSync()) as Map<String, Object?>,
          ),
        );
      } on FormatException {
        // A torn write that lost the rename race: skip, never crash.
        continue;
      }
    }
    return out;
  }

  void writeAtomicSync(WorkflowCheckpoint checkpoint) {
    directory.createSync(recursive: true);
    final target = fileFor(checkpoint.executionId);
    final tmp = File(
      '${target.path}.${DateTime.now().microsecondsSinceEpoch}.tmp',
    );
    tmp.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(checkpoint.toJson()),
    );
    tmp.renameSync(target.path);
  }

  void deleteSync(String executionId) {
    final f = fileFor(executionId);
    if (f.existsSync()) f.deleteSync();
  }
}

const _terminalStates = {'succeeded', 'cancelled', 'failed'};

/// Classifies checkpoints into the four canonical recovery options.
WorkflowRecoveryOption recommendOption(WorkflowCheckpoint checkpoint) =>
    checkpoint.completedSteps.isEmpty
    ? WorkflowRecoveryOption.restart
    : WorkflowRecoveryOption.resumeFromCheckpoint;

class WorkflowRecoveryService {
  WorkflowRecoveryService({required this.store});

  final WorkflowCheckpointStore store;

  /// All runs whose last checkpoint shows a NON-terminal state — i.e. the
  /// process died mid-run (or was force-closed) and the user must decide.
  List<WorkflowCheckpoint> detectInterruptedSync() => store
      .listAllSync()
      .where((c) => !_terminalStates.contains(c.currentState))
      .toList();

  /// RESUME_FROM_CHECKPOINT — completed steps are pre-marked done; they do
  /// NOT re-execute.
  WorkflowExecutionHandle resumeFromCheckpoint({
    required WorkflowRunner runner,
    required WorkflowCheckpoint checkpoint,
    required WorkflowDefinition workflow,
    required WorkflowExecutionPlan plan,
    required Future<Object?> Function(
      WorkflowStep step,
      JobContext context,
      int attempt,
    )
    work,
  }) {
    return runner.startFromCheckpoint(
      workflow: workflow,
      plan: plan,
      work: work,
      executionId: checkpoint.executionId,
      completedSteps: checkpoint.completedSteps,
    );
  }

  /// CANCEL_AND_CLEANUP — remove the stale checkpoint.
  void cancelAndCleanupSync(String executionId) =>
      store.deleteSync(executionId);
}
