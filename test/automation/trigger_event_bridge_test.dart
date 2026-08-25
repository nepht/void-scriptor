import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/automation/automation_condition.dart';
import 'package:void_scriptor/automation/trigger_event_bridge.dart';
import 'package:void_scriptor/automation/trigger_registry.dart';
import 'package:void_scriptor/automation/workflow_trigger.dart';
import 'package:void_scriptor/core/commands/command_bus.dart';
import 'package:void_scriptor/core/commands/command_event_bus.dart';

/// Sprint 104 / 104.8 — wire workflow triggers onto the EXISTING universal
/// event bus. No second bus may be created; subscriptions must be cleanable;
/// events are validated against trigger configuration before any firing.
WorkflowTrigger projectTrigger(
  String id,
  String eventName, {
  bool enabled = true,
}) => WorkflowTrigger(
  triggerId: id,
  type: WorkflowTriggerType.projectEvent,
  configuration: {'eventName': eventName},
  enabled: enabled,
  createdAt: DateTime.utc(2026, 8, 25),
  updatedAt: DateTime.utc(2026, 8, 25),
);

ProjectMutationEvent mutation(
  String commandType, {
  String projectId = 'p-1',
  int sequence = 1,
  String source = 'workspace',
  CommandEventType type = CommandEventType.commandExecuted,
}) => ProjectMutationEvent(
  projectId: projectId,
  commandType: commandType,
  sequence: sequence,
  type: type,
  source: source,
);

void main() {
  test('fires a matching projectEvent trigger with validated event facts', () {
    final bus = CommandEventBus();
    final fired = <AutomationTriggerFire>[];
    final bridge = AutomationTriggerBridge(
      eventBus: bus,
      triggers: [projectTrigger('t-1', 'character.renamed')],
      onFire: fired.add,
    );

    bus.publish(mutation('character.renamed'));

    expect(fired, hasLength(1));
    expect(fired.single.trigger.triggerId, 't-1');
    expect(fired.single.context.facts['commandType'], 'character.renamed');
    expect(fired.single.context.facts['projectId'], 'p-1');
    expect(fired.single.context.facts['sequence'], 1);
    expect(fired.single.context.facts['eventType'], 'commandExecuted');
    bridge.dispose();
  });

  test('does not fire when the event name does not match configuration', () {
    final bus = CommandEventBus();
    final fired = <AutomationTriggerFire>[];
    final bridge = AutomationTriggerBridge(
      eventBus: bus,
      triggers: [projectTrigger('t-1', 'scene.created')],
      onFire: fired.add,
    );

    bus.publish(mutation('character.renamed'));
    expect(fired, isEmpty);
    bridge.dispose();
  });

  test('fails closed on a projectEvent trigger without eventName', () {
    final bus = CommandEventBus();
    final fired = <AutomationTriggerFire>[];
    final bad = WorkflowTrigger(
      triggerId: 't-bad',
      type: WorkflowTriggerType.projectEvent,
      configuration: const {},
      createdAt: DateTime.utc(2026, 8, 25),
      updatedAt: DateTime.utc(2026, 8, 25),
    );
    final bridge = AutomationTriggerBridge(
      eventBus: bus,
      triggers: [bad],
      onFire: fired.add,
    );

    bus.publish(mutation('anything'));
    expect(fired, isEmpty);
    expect(bridge.attachIssues, isNotEmpty);
    bridge.dispose();
  });

  test('fails closed on a disabled or unregistered-type trigger', () {
    final bus = CommandEventBus();
    final fired = <AutomationTriggerFire>[];
    // A restrictive registry without projectEvent proves registry gating.
    const restricted = WorkflowTriggerRegistry(registeredTypes: {});
    final bridge = AutomationTriggerBridge(
      eventBus: bus,
      triggers: [
        projectTrigger('t-off', 'character.renamed', enabled: false),
        projectTrigger('t-reg', 'character.renamed'),
      ],
      registry: restricted,
      onFire: fired.add,
    );

    bus.publish(mutation('character.renamed'));
    expect(fired, isEmpty);
    // t-off: unregistered + disabled; t-reg: unregistered under restriction.
    expect(bridge.attachIssues.length, 3);
    bridge.dispose();
  });

  test('non-event trigger types are not driven by the mutation bus', () {
    final bus = CommandEventBus();
    final fired = <AutomationTriggerFire>[];
    final schedule = WorkflowTrigger(
      triggerId: 't-sched',
      type: WorkflowTriggerType.schedule,
      configuration: {'cron': '* * * * *'},
      createdAt: DateTime.utc(2026, 8, 25),
      updatedAt: DateTime.utc(2026, 8, 25),
    );
    final bridge = AutomationTriggerBridge(
      eventBus: bus,
      triggers: [schedule],
      onFire: fired.add,
    );

    bus.publish(mutation('character.renamed'));
    expect(fired, isEmpty);
    bridge.dispose();
  });

  test('dispose stops all future firings and is safe to call twice', () {
    final bus = CommandEventBus();
    final fired = <AutomationTriggerFire>[];
    final bridge = AutomationTriggerBridge(
      eventBus: bus,
      triggers: [projectTrigger('t-1', 'character.renamed')],
      onFire: fired.add,
    );

    bridge.dispose();
    bridge.dispose();

    // Publishing after close of the bus itself throws; use a second publish
    // path: our bridge must simply never fire again for live buses too.
    final bus2 = CommandEventBus();
    final bridge2 = AutomationTriggerBridge(
      eventBus: bus2,
      triggers: [projectTrigger('t-2', 'character.renamed')],
      onFire: fired.add,
    );
    bridge2.dispose();
    bus2.publish(mutation('character.renamed'));
    expect(fired, isEmpty);
  });

  test('conditions are evaluated by the caller using provided facts', () {
    // The bridge stays at trigger level; rule condition evaluation is owned
    // by the condition engine (104.6). This pins the intended composition.
    final engine = const AutomationConditionEngine().allMatch(
      [
        const AutomationCondition(
          field: 'commandType',
          op: ConditionOperator.equals,
          value: 'character.renamed',
        ),
      ],
      const AutomationContext(
        facts: {
          'projectId': 'p-1',
          'commandType': 'character.renamed',
          'sequence': 3,
          'source': 'workspace',
          'eventType': 'commandExecuted',
        },
      ),
    );
    expect(engine, isTrue);
  });
}
