import 'workflow_definition.dart';

/// Sprint 103 / 103.7 + 103.12 — explicit execution state machine and the
/// deterministic dependency resolver over the step graph.

/// Nine canonical execution states (103.7).
enum WorkflowExecutionState {
  queued,
  running,
  pausing,
  paused,
  cancelling,
  cancelled,
  succeeded,
  failed,
  recovering;

  /// Allowed forward transitions. Terminal states accept nothing.
  static const Map<WorkflowExecutionState, Set<WorkflowExecutionState>>
  _transitions = {
    queued: {running, cancelling, cancelled},
    running: {pausing, cancelling, succeeded, failed},
    pausing: {paused, cancelling},
    paused: {running, cancelling},
    cancelling: {cancelled},
    failed: {recovering},
    recovering: {running, cancelled},
    cancelled: {},
    succeeded: {},
  };

  /// Case-insensitive transition guard.
  bool canGoTo(String targetName) {
    final targets = _transitions[this] ?? const {};
    return targets.any((s) => s.name == targetName.toLowerCase());
  }

  /// Case-insensitive lookup; throws [ArgumentError] when unknown.
  static WorkflowExecutionState byName(String name) {
    final lower = name.toLowerCase();
    for (final s in values) {
      if (s.name == lower) return s;
    }
    throw ArgumentError.value(name, 'name', 'unknown workflow state');
  }
}

/// Thrown when the step graph contains a dependency cycle.
class WorkflowCycleException implements Exception {
  WorkflowCycleException(this.cycle);

  /// Step ids participating in the cycle (deterministic walk order).
  final List<String> cycle;

  @override
  String toString() =>
      'WorkflowCycleException: dependency cycle through $cycle';
}

/// Thrown when a step depends on an id that does not exist.
class UnknownStepReference implements Exception {
  UnknownStepReference(this.stepId, this.dependency);

  final String stepId;
  final String dependency;

  @override
  String toString() =>
      'UnknownStepReference: step "$stepId" depends on unknown "$dependency"';
}

/// Resolved execution plan: a deterministic total order plus readiness sets
/// computed from the captured dependency graph.
class WorkflowExecutionPlan {
  WorkflowExecutionPlan({
    required List<String> executionOrder,
    required Map<String, List<String>> dependencies,
  }) : _order = List.of(executionOrder),
       _deps = {for (final e in dependencies.entries) e.key: List.of(e.value)};

  final List<String> _order;
  final Map<String, List<String>> _deps;

  /// Deterministic total execution order (Kahn + declaration-order ties).
  List<String> get executionOrder => List.of(_order);

  /// Steps ready once [index] steps have completed: the next step in order
  /// plus any later independent steps.
  Set<String> readyAt(int index) {
    final completed = _order.take(index).toSet();
    return {
      for (var i = index; i < _order.length; i++)
        if (_deps[_order[i]]!.every(completed.contains)) _order[i],
    };
  }
}

/// Kahn-style resolution with declaration-order tie-breaking so plans are
/// reproducible across runs (103.12 deterministic_order).
class WorkflowDependencyResolver {
  WorkflowExecutionPlan plan(WorkflowDefinition definition) {
    final deps = <String, List<String>>{};
    for (final step in definition.steps) {
      for (final d in step.dependsOn) {
        if (!definition.steps.any((s) => s.stepId == d)) {
          throw UnknownStepReference(step.stepId, d);
        }
      }
      deps[step.stepId] = List.of(step.dependsOn);
    }

    final byId = {for (final s in definition.steps) s.stepId: s};
    final remaining = List.of(definition.steps);
    final done = <String>{};
    final order = <String>[];

    while (remaining.isNotEmpty) {
      WorkflowStep? picked;
      for (final candidate in remaining) {
        if (candidate.dependsOn.every(done.contains)) {
          picked = candidate;
          break;
        }
      }
      if (picked == null) {
        throw WorkflowCycleException(_extractCycle(remaining, byId));
      }
      order.add(picked.stepId);
      done.add(picked.stepId);
      remaining.remove(picked);
    }

    return WorkflowExecutionPlan(executionOrder: order, dependencies: deps);
  }

  /// Walk deterministically from the lowest-id remaining step until a node
  /// repeats; the walked suffix is a concrete cycle to report.
  List<String> _extractCycle(
    List<WorkflowStep> remaining,
    Map<String, WorkflowStep> byId,
  ) {
    final startId = remaining
        .map((s) => s.stepId)
        .reduce((a, b) => a.compareTo(b) <= 0 ? a : b);
    final seen = <String>[];
    var cursor = startId;
    while (!seen.contains(cursor)) {
      seen.add(cursor);
      final unresolved = byId[cursor]!.dependsOn.where(seen.contains).toSet();
      if (unresolved.isEmpty) {
        // No back-edge yet: continue into the smallest-id unresolved dep.
        final next = byId[cursor]!.dependsOn.toSet().difference(seen.toSet());
        if (next.isEmpty) break;
        cursor = next.reduce((a, b) => a.compareTo(b) <= 0 ? a : b);
      } else {
        cursor = unresolved.reduce((a, b) => a.compareTo(b) <= 0 ? a : b);
        // Close the cycle: slice from its first occurrence.
        return seen.sublist(seen.indexOf(cursor));
      }
    }
    return seen;
  }
}
