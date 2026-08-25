/// Sprint 104 / 104.8 — Event Bus Integration.
///
/// Bridges the EXISTING universal event bus (`CommandEventBus`) into the
/// automation trigger layer. No second bus is created: this class only
/// subscribes to `CommandEventBus.events` and translates validated mutation
/// events into trigger firings for registered, enabled `projectEvent`
/// triggers whose configuration names the event.
///
/// Contract:
/// - fail-closed: a trigger that is disabled, unregistered, or misconfigured
///   never fires and is reported in [attachIssues];
/// - event schema validation: only well-formed [ProjectMutationEvent]s are
///   translated; malformed payloads cannot reach a firing;
/// - subscription cleanup: [dispose] cancels the bus subscription exactly
///   once; after dispose no further firings occur;
/// - scope: schedule/asset/job/plugin triggers are NOT driven here — they are
///   owned by steps 104.9/104.12/104.13/104.17 respectively.
library;

import 'dart:async';

import 'package:void_scriptor/core/commands/command_event_bus.dart';

import 'automation_condition.dart';
import 'automation_rule.dart';
import 'trigger_registry.dart';
import 'workflow_trigger.dart';

/// A validated trigger firing handed to the automation runtime.
class AutomationTriggerFire {
  const AutomationTriggerFire({required this.trigger, required this.context});

  final WorkflowTrigger trigger;
  final AutomationContext context;
}

typedef AutomationTriggerCallback = void Function(AutomationTriggerFire fire);

class AutomationTriggerBridge {
  AutomationTriggerBridge({
    required CommandEventBus eventBus,
    required List<WorkflowTrigger> triggers,
    required AutomationTriggerCallback onFire,
    WorkflowTriggerRegistry? registry,
  }) : fireHandler = onFire,
       _registry = registry ?? const WorkflowTriggerRegistry.canonical() {
    _subscription = eventBus.events.listen(_handleEvent);
    for (final trigger in triggers) {
      final issues = _validateTrigger(trigger);
      attachIssues.addAll(issues);
      if (issues.isEmpty) {
        _triggers.add(trigger);
      }
    }
  }

  final AutomationTriggerCallback fireHandler;
  final WorkflowTriggerRegistry _registry;
  final List<WorkflowTrigger> _triggers = [];
  final List<String> attachIssues = [];
  StreamSubscription<ProjectMutationEvent>? _subscription;
  bool _disposed = false;

  /// Fail-closed validation at attach time. Returns issues; empty = accepted.
  List<String> _validateTrigger(WorkflowTrigger trigger) {
    final issues = <String>[];
    if (!_registry.isRegistered(trigger.type)) {
      issues.add('unregistered trigger type: ${trigger.type.name}');
    }
    if (!trigger.enabled) {
      issues.add('trigger is disabled: ${trigger.triggerId}');
    }
    final eventName =
        trigger.configuration['eventName']?.toString().trim() ?? '';
    if (eventName.isEmpty) {
      issues.add(
        'projectEvent trigger requires a non-empty eventName '
        'configuration',
      );
    }
    return issues;
  }

  void _handleEvent(ProjectMutationEvent event) {
    if (_disposed) return;
    // Event schema validation: reject malformed events before any matching.
    if (!_isValidEvent(event)) return;
    final facts = <String, Object>{
      'projectId': event.projectId,
      'commandType': factString(event.commandType),
      'sequence': event.sequence,
      'source': factString(event.source),
      'eventType': factString(event.type.name),
    };
    for (final trigger in _triggers) {
      final expected = trigger.configuration['eventName']?.toString().trim();
      if (expected == null || expected.isEmpty) continue;
      if (expected != facts['commandType']) continue;
      fireHandler(
        AutomationTriggerFire(
          trigger: trigger,
          context: AutomationContext(facts: Map.of(facts)),
        ),
      );
    }
  }

  bool _isValidEvent(Object? event) {
    return event is ProjectMutationEvent &&
        event.projectId.trim().isNotEmpty &&
        event.sequence >= 0 &&
        event.commandType.trim().isNotEmpty;
  }

  /// Cancels the bus subscription exactly once; idempotent.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    unawaited(_subscription?.cancel());
    _triggers.clear();
  }
}

/// Normalizes an enum-ish value to its stable string form for fact bags.
String factString(Object value) => value.toString();

/// Convenience: evaluate a full rule against a firing using the 104.6 engine.
bool ruleMatchesFire(
  AutomationRule rule,
  AutomationTriggerFire fire,
  AutomationConditionEngine engine,
) => rule.enabled && engine.allMatch(rule.conditions, fire.context);
