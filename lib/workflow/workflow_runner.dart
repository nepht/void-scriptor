import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../core/jobs/background_job.dart';
import '../core/jobs/background_job_queue.dart';
import 'workflow_definition.dart';
import 'workflow_execution.dart';
import 'workflow_policies.dart';

/// Sprint 103 / 103.8-103.16 — Workflow Runner on the EXISTING runtime.
///
/// Hard rules from the canonical spec:
///   * reuse [BackgroundJobQueue]/[BackgroundTask]; building a second job
///     engine is forbidden (103.8);
///   * cooperative cancellation ([JobContext.isCancelled]); cancellation
///     lands instantly for queued steps, at the running step boundary
///     otherwise (103.13, documented limitation);
///   * pause/resume at step boundaries only — no process freeze (103.14);
///   * checkpoints are written atomically (tmp + rename, 103.15);
///   * timeouts are audited (103.18); failures follow explicit policies
///     (103.19).

enum WorkflowRunnerEventKind {
  started,
  stepStarted,
  stepSucceeded,
  stepFailed,
  stepSkipped,
  stepTimedOut,
  paused,
  resumed,
  cancelled,
  completed,
}

class WorkflowRunnerEvent {
  const WorkflowRunnerEvent({
    required this.kind,
    required this.executionId,
    this.stepId,
    this.detail,
  });

  final WorkflowRunnerEventKind kind;
  final String executionId;
  final String? stepId;
  final String? detail;

  @override
  String toString() =>
      'WorkflowRunnerEvent($kind, exec=$executionId, step=$stepId'
      '${detail == null ? '' : ', $detail'})';
}

enum WorkflowStepOutcome { succeeded, skipped, failed }

typedef StepCommandFactory =
    dynamic Function(WorkflowStep step, Map<String, Object?> inputs);

/// One workflow step executed INSIDE the existing queue as a task.
class WorkflowStepTask implements BackgroundTask {
  WorkflowStepTask({
    required this.executionId,
    required this.step,
    required this.timeoutPolicy,
    required this.retryPolicy,
    required this.failurePolicy,
    required this.onEvent,
    required this.onOutcome,
    this.work,
  });

  final String executionId;
  final WorkflowStep step;
  final WorkflowTimeoutPolicy timeoutPolicy;
  final WorkflowRetryPolicy retryPolicy;
  final WorkflowFailurePolicy failurePolicy;
  final void Function(WorkflowRunnerEvent event) onEvent;

  /// Called exactly once with the terminal outcome of this step.
  final void Function(WorkflowStepTask task, WorkflowStepOutcome outcome)
  onOutcome;

  /// Injectable unit of work; defaults to a no-op (runner tests use fake
  /// work). Real executions inject closures that drive app commands.
  final Future<Object?> Function(JobContext context, int attempt)? work;

  int _attempt = 0;
  bool _terminalReported = false;

  @override
  String get id => 'wf-$executionId-${step.stepId}';

  @override
  String? get taskKey => id;

  @override
  BackgroundJobType get type => BackgroundJobType.custom;

  @override
  Set<JobResource> get resources => {JobResource.cpu};

  @override
  BackgroundJob get job => BackgroundJob(
    id: id,
    projectId: 'workflow',
    type: type,
    label: 'workflow:$executionId:${step.stepId}',
    status: BackgroundJobStatus.queued,
    priority: BackgroundJobPriority.normal,
    createdAt: DateTime.now(),
  );

  @override
  Future<void> cancel() async {}

  @override
  Future<void> execute(JobContext context) async {
    while (true) {
      _attempt += 1;
      if (context.isCancelled()) {
        _report(WorkflowStepOutcome.failed, cancelled: true);
        return;
      }
      try {
        final unit = work;
        if (unit != null) {
          await unit(context, _attempt).timeout(timeoutPolicy.perStep);
        }
        _report(WorkflowStepOutcome.succeeded);
        return;
      } on TimeoutException catch (e) {
        onEvent(
          WorkflowRunnerEvent(
            kind: WorkflowRunnerEventKind.stepTimedOut,
            executionId: executionId,
            stepId: step.stepId,
            detail: 'attempt $_attempt',
          ),
        );
        final continueAfterTimeout = _handleFailure(
          e,
          errorCode: 'transient.timeout',
          cancelled: () => false,
        );
        if (!continueAfterTimeout) return;
      } catch (error) {
        final continueAfterError = _handleFailure(
          error,
          errorCode: 'transient.io',
          cancelled: context.isCancelled,
        );
        if (!continueAfterError) return;
      }
    }
  }

  /// Returns true when the execute() loop may start another attempt;
  /// false when a terminal outcome was reported.
  bool _handleFailure(
    Object error, {
    required String errorCode,
    required bool Function() cancelled,
  }) {
    if (cancelled()) {
      _report(WorkflowStepOutcome.failed, cancelled: true);
      return false;
    }
    if (retryPolicy.shouldRetry(errorCode: errorCode, attempt: _attempt)) {
      onEvent(
        WorkflowRunnerEvent(
          kind: WorkflowRunnerEventKind.stepFailed,
          executionId: executionId,
          stepId: step.stepId,
          detail: 'retry scheduled ($_attempt): $error',
        ),
      );
      return true; // loop continues -> next attempt
    }
    switch (failurePolicy) {
      case WorkflowFailurePolicy.skipIfOptional when step.isOptional:
        onEvent(
          WorkflowRunnerEvent(
            kind: WorkflowRunnerEventKind.stepSkipped,
            executionId: executionId,
            stepId: step.stepId,
            detail: '$error',
          ),
        );
        _report(WorkflowStepOutcome.skipped);
        return false;
      case WorkflowFailurePolicy.requireUserDecision:
        _report(WorkflowStepOutcome.failed, userDecision: true);
        return false;
      default:
        onEvent(
          WorkflowRunnerEvent(
            kind: WorkflowRunnerEventKind.stepFailed,
            executionId: executionId,
            stepId: step.stepId,
            detail: '$error',
          ),
        );
        _report(WorkflowStepOutcome.failed);
        return false;
    }
  }

  void _report(
    WorkflowStepOutcome outcome, {
    bool cancelled = false,
    bool userDecision = false,
  }) {
    if (_terminalReported) return;
    _terminalReported = true;
    _userDecisionRequested = userDecision;
    _cancelledReported = cancelled;
    onOutcome(this, outcome);
  }

  bool _userDecisionRequested = false;
  bool _cancelledReported = false;
  bool get userDecisionRequested => _userDecisionRequested;
  bool get cancelledReported => _cancelledReported;
}

/// In-memory snapshot of one execution's progress (103.15 payload).
class WorkflowCheckpoint {
  WorkflowCheckpoint({
    required this.executionId,
    required this.workflowId,
    required this.workflowVersion,
    List<String> completedSteps = const [],
    this.currentState = 'running',
    Map<String, String> outputReferences = const {},
    DateTime? timestamp,
  }) : completedSteps = List.of(completedSteps),
       outputReferences = Map.of(outputReferences),
       timestamp = timestamp ?? DateTime.now().toUtc();

  final String executionId;
  final String workflowId;
  final int workflowVersion;
  final List<String> completedSteps;
  final String currentState;
  final Map<String, String> outputReferences;
  final DateTime timestamp;

  Map<String, Object?> toJson() => {
    'execution_id': executionId,
    'workflow_id': workflowId,
    'workflow_version': workflowVersion,
    'completed_steps': completedSteps,
    'current_state': currentState,
    'output_references': outputReferences,
    'timestamp': timestamp.toIso8601String(),
  };

  static WorkflowCheckpoint fromJson(Map<String, Object?> json) =>
      WorkflowCheckpoint(
        executionId: json['execution_id']! as String,
        workflowId: json['workflow_id']! as String,
        workflowVersion: json['workflow_version']! as int,
        completedSteps: (json['completed_steps']! as List).cast<String>(),
        currentState: json['current_state']! as String,
        outputReferences: (json['output_references']! as Map)
            .cast<String, String>(),
        timestamp: DateTime.parse(json['timestamp']! as String),
      );
}

/// Atomic (tmp + rename) checkpoint persistence (103.15).
class WorkflowCheckpointStore {
  WorkflowCheckpointStore(this.directory);

  final Directory directory;

  File fileFor(String executionId) => File(
    '${directory.path}${Platform.pathSeparator}'
    'workflow-checkpoint-$executionId.json',
  );

  Future<void> writeAtomic(WorkflowCheckpoint checkpoint) async {
    await directory.create(recursive: true);
    final target = fileFor(checkpoint.executionId);
    // Unique tmp name per write: two executions of the same workflow id must
    // never steal each other's rename target.
    final tmp = File(
      '${target.path}.${DateTime.now().microsecondsSinceEpoch}.tmp',
    );
    await tmp.writeAsString(
      const JsonEncoder.withIndent('  ').convert(checkpoint.toJson()),
    );
    await tmp.rename(target.path);
  }

  Future<WorkflowCheckpoint?> read(String executionId) async {
    final f = fileFor(executionId);
    if (!await f.exists()) return null;
    final decoded = jsonDecode(await f.readAsString()) as Map<String, Object?>;
    return WorkflowCheckpoint.fromJson(decoded);
  }

  Future<void> delete(String executionId) async {
    final f = fileFor(executionId);
    if (await f.exists()) await f.delete();
  }
}

/// Crash-recovery options (103.16) — offered honestly, never auto-applied.
enum WorkflowRecoveryOption {
  resumeFromCheckpoint,
  restart,
  cancelAndCleanup,
  inspectOnly,
}

/// One live execution managed by [WorkflowRunner].
class WorkflowExecutionHandle {
  WorkflowExecutionHandle._(this.executionId, this._done);

  final String executionId;
  final Completer<WorkflowExecutionResult> _done;
  void Function()? relaunch;
  WorkflowDefinition? workflow;
  WorkflowExecutionState state = WorkflowExecutionState.running;
  final Set<String> launched = {};
  final Set<String> finished = {};
  final Set<String> successes = {};
  bool paused = false;
  bool cancelRequested = false;
  final Map<String, WorkflowStepTask> tasks = {};

  Future<WorkflowExecutionResult> get result => _done.future;
}

class WorkflowExecutionResult {
  WorkflowExecutionResult({
    required this.executionId,
    required this.state,
    required this.completedSteps,
    this.error,
  });

  final String executionId;
  final WorkflowExecutionState state;
  final List<String> completedSteps;
  final String? error;
}

/// Orchestrates workflow executions over the EXISTING BackgroundJobQueue.
class WorkflowRunner {
  WorkflowRunner({required this.queue, this.checkpointDirectory});

  final BackgroundJobQueue queue;
  final Directory? checkpointDirectory;
  final StreamController<WorkflowRunnerEvent> _events =
      StreamController.broadcast();
  final Map<String, WorkflowExecutionHandle> _live = {};

  Stream<WorkflowRunnerEvent> get events => _events.stream;

  /// Starts one execution. [work] builds the actual unit of work per step
  /// (real runs wrap AppCommand execution here).
  WorkflowExecutionHandle start({
    required WorkflowDefinition workflow,
    required WorkflowExecutionPlan plan,
    required Future<Object?> Function(
      WorkflowStep step,
      JobContext context,
      int attempt,
    )
    work,
    String? executionId,
  }) {
    final id = executionId ?? 'exec-${DateTime.now().microsecondsSinceEpoch}';
    final handle = WorkflowExecutionHandle._(id, Completer());
    _live[id] = handle;
    _events.add(
      WorkflowRunnerEvent(
        kind: WorkflowRunnerEventKind.started,
        executionId: id,
      ),
    );
    // Deferred one microtask: an immediate cancel()/pause() must win the
    // race against the first launch (103.13/103.14 semantics).
    handle.relaunch = () => _launchReady(handle, workflow, plan, work);
    handle.workflow = workflow;
    Future<void>.microtask(handle.relaunch!);
    return handle;
  }

  /// Crash recovery (103.16): resume with steps already completed before
  /// the interruption pre-marked as finished — they never re-execute.
  WorkflowExecutionHandle startFromCheckpoint({
    required WorkflowDefinition workflow,
    required WorkflowExecutionPlan plan,
    required Future<Object?> Function(
      WorkflowStep step,
      JobContext context,
      int attempt,
    )
    work,
    required String executionId,
    required List<String> completedSteps,
  }) {
    final id = executionId;
    final handle = WorkflowExecutionHandle._(id, Completer());
    _live[id] = handle;
    for (final stepId in completedSteps) {
      if (plan.executionOrder.contains(stepId)) {
        handle.finished.add(stepId);
        handle.successes.add(stepId);
        handle.launched.add(stepId);
      }
    }
    _events.add(
      WorkflowRunnerEvent(
        kind: WorkflowRunnerEventKind.started,
        executionId: id,
        detail: 'resumed from checkpoint',
      ),
    );
    handle.relaunch = () => _launchReady(handle, workflow, plan, work);
    handle.workflow = workflow;
    Future<void>.microtask(handle.relaunch!);
    return handle;
  }

  /// Pause takes effect at the next step boundary (103.14).
  void pause(String executionId) {
    final h = _live[executionId];
    if (h == null) return;
    h.paused = true;
    h.state = WorkflowExecutionState.paused;
    _events.add(
      WorkflowRunnerEvent(
        kind: WorkflowRunnerEventKind.paused,
        executionId: executionId,
      ),
    );
  }

  /// Resume relaunches ready steps; no-op when the run already ended.
  void resume(String executionId) {
    final h = _live[executionId];
    if (h == null) return;
    h.paused = false;
    h.state = WorkflowExecutionState.running;
    _events.add(
      WorkflowRunnerEvent(
        kind: WorkflowRunnerEventKind.resumed,
        executionId: executionId,
      ),
    );
    h.relaunch?.call();
  }

  /// Cooperative cancel: queued steps die instantly; the running step is
  /// signalled and ends at its next cancellation check (103.13).
  Future<void> cancel(String executionId) async {
    final h = _live[executionId];
    if (h == null) return;
    h.cancelRequested = true;
    h.state = WorkflowExecutionState.cancelling;
    for (final taskId in List.of(h.tasks.keys)) {
      await queue.cancel(h.tasks[taskId]!.id);
    }
    _events.add(
      WorkflowRunnerEvent(
        kind: WorkflowRunnerEventKind.cancelled,
        executionId: executionId,
      ),
    );
    // Nothing was ever launched (cancel raced the deferred start): finish.
    if (h.tasks.isEmpty) {
      _finish(h, WorkflowExecutionState.cancelled);
    }
  }

  void _launchReady(
    WorkflowExecutionHandle handle,
    WorkflowDefinition workflow,
    WorkflowExecutionPlan plan,
    Future<Object?> Function(WorkflowStep step, JobContext context, int attempt)
    work,
  ) {
    if (handle.cancelRequested || handle.paused) return;
    final ready = plan.readyAt(handle.finished.length);
    for (final stepId in plan.executionOrder) {
      if (!ready.contains(stepId) || handle.launched.contains(stepId)) continue;
      final step = workflow.steps.firstWhere((s) => s.stepId == stepId);
      handle.launched.add(stepId);
      final task = WorkflowStepTask(
        executionId: handle.executionId,
        step: step,
        timeoutPolicy: WorkflowTimeoutPolicy(perStep: step.timeout),
        retryPolicy: step.retryPolicy,
        failurePolicy: step.effectiveFailurePolicy,
        onEvent: _events.add,
        onOutcome: (task, outcome) =>
            _onStepDone(handle, workflow, plan, work, stepId, outcome, task),
        work: (context, attempt) => work(step, context, attempt),
      );
      handle.tasks[stepId] = task;
      _events.add(
        WorkflowRunnerEvent(
          kind: WorkflowRunnerEventKind.stepStarted,
          executionId: handle.executionId,
          stepId: stepId,
        ),
      );
      final accepted = queue.enqueue(task);
      assert(accepted, 'unique per-execution task keys must be accepted');
    }
    if (ready.isNotEmpty) {
      unawaited(queue.drain());
    }
  }

  Future<void> _onStepDone(
    WorkflowExecutionHandle handle,
    WorkflowDefinition workflow,
    WorkflowExecutionPlan plan,
    Future<Object?> Function(WorkflowStep step, JobContext context, int attempt)
    work,
    String stepId,
    WorkflowStepOutcome outcome,
    WorkflowStepTask task,
  ) async {
    handle.tasks.remove(stepId);
    switch (outcome) {
      case WorkflowStepOutcome.succeeded:
        handle.finished.add(stepId);
        handle.successes.add(stepId);
        break;
      case WorkflowStepOutcome.skipped:
        handle.finished.add(stepId);
        break;
      case WorkflowStepOutcome.failed:
        if (task.cancelledReported) {
          _finish(handle, WorkflowExecutionState.cancelled);
          return;
        }
        if (task.userDecisionRequested) {
          handle.state = WorkflowExecutionState.pausing;
          _events.add(
            WorkflowRunnerEvent(
              kind: WorkflowRunnerEventKind.paused,
              executionId: handle.executionId,
              stepId: stepId,
              detail: 'user decision required',
            ),
          );
          return;
        }
        _failRemaining(handle, plan, stepId);
        return;
    }
    // Persist checkpoint after every completed step (103.15) and AWAIT it
    // so the run cannot complete before its own checkpoint is durable.
    await _persistCheckpoint(handle, workflow);
    if (handle.finished.length == plan.executionOrder.length) {
      _finish(handle, WorkflowExecutionState.succeeded);
      return;
    }
    _launchReady(handle, workflow, plan, work);
    if (handle.launched.isEmpty && handle.tasks.isEmpty) {
      // Nothing launchable left (paused before any start).
      handle.state = WorkflowExecutionState.paused;
    }
  }

  void _failRemaining(
    WorkflowExecutionHandle handle,
    WorkflowExecutionPlan plan,
    String failedStepId,
  ) {
    for (final entry in handle.tasks.entries) {
      queue.cancel(entry.value.id);
    }
    handle.state = WorkflowExecutionState.failed;
    _finish(
      handle,
      WorkflowExecutionState.failed,
      error: 'step $failedStepId failed',
    );
  }

  Future<void> _persistCheckpoint(
    WorkflowExecutionHandle handle,
    WorkflowDefinition workflow,
  ) async {
    final dir = checkpointDirectory;
    if (dir == null) return;
    final checkpoint = WorkflowCheckpoint(
      executionId: handle.executionId,
      workflowId: workflow.workflowId,
      workflowVersion: workflow.version,
      completedSteps: _snapshotOf(handle),
      currentState: handle.state.name,
    );
    await _store.writeAtomic(checkpoint);
  }

  List<String> _snapshotOf(WorkflowExecutionHandle handle) =>
      handle.finished.toList()..sort();

  late final WorkflowCheckpointStore _store = WorkflowCheckpointStore(
    checkpointDirectory!,
  );

  Future<void> _finish(
    WorkflowExecutionHandle handle,
    WorkflowExecutionState state, {
    String? error,
  }) async {
    handle.state = state;
    _live.remove(handle.executionId);
    // Rewrite the checkpoint with the TERMINAL state so a later crash
    // recovery never reads a stale 'running' for a finished run (103.15).
    final wf = handle.workflow;
    if (wf != null && checkpointDirectory != null) {
      final checkpoint = WorkflowCheckpoint(
        executionId: handle.executionId,
        workflowId: wf.workflowId,
        workflowVersion: wf.version,
        completedSteps: _snapshotOf(handle),
        currentState: state.name,
      );
      // Await the terminal write so a reader can never observe the run as
      // finished while its checkpoint still says 'running'.
      await _store.writeAtomic(checkpoint);
    }
    _events.add(
      WorkflowRunnerEvent(
        kind: state == WorkflowExecutionState.succeeded
            ? WorkflowRunnerEventKind.completed
            : WorkflowRunnerEventKind.cancelled,
        executionId: handle.executionId,
        detail: error,
      ),
    );
    if (!handle._done.isCompleted) {
      handle._done.complete(
        WorkflowExecutionResult(
          executionId: handle.executionId,
          state: state,
          completedSteps: handle.successes.toList()..sort(),
          error: error,
        ),
      );
    }
  }
}
