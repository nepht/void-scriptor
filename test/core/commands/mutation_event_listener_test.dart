import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/commands/command_bus.dart';
import 'package:void_scriptor/core/commands/command_event_bus.dart';

void main() {
  test('MutationEventListener stops receiving events after dispose', () async {
    final bus = CommandEventBus();
    var received = 0;
    final listener = MutationEventListener(
      bus,
      onMutation: (_) async => received++,
    );

    bus.publish(
      const ProjectMutationEvent(
        projectId: 'p1',
        commandType: 'test',
        sequence: 1,
        type: CommandEventType.commandExecuted,
        source: 'test',
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(received, 1);

    await listener.dispose();
    bus.publish(
      const ProjectMutationEvent(
        projectId: 'p1',
        commandType: 'test',
        sequence: 2,
        type: CommandEventType.commandExecuted,
        source: 'test',
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(received, 1);

    await bus.close();
  });

  test('CommandEventBus rejects publish after close', () async {
    final bus = CommandEventBus();
    await bus.close();

    expect(
      () => bus.publish(
        const ProjectMutationEvent(
          projectId: 'p1',
          commandType: 'test',
          sequence: 1,
          type: CommandEventType.commandExecuted,
          source: 'test',
        ),
      ),
      throwsStateError,
    );
  });
}
