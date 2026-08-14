import 'dart:async';

import 'command_bus.dart';

class ProjectMutationEvent {
  const ProjectMutationEvent({
    required this.projectId,
    required this.commandType,
    required this.sequence,
    required this.type,
    required this.source,
  });

  final String projectId;
  final String commandType;
  final int sequence;
  final CommandEventType type;
  final String source;
}

class CommandEventBus {
  final StreamController<ProjectMutationEvent> _controller =
      StreamController<ProjectMutationEvent>.broadcast(sync: true);

  Stream<ProjectMutationEvent> get events => _controller.stream;

  void publish(ProjectMutationEvent event) {
    if (_controller.isClosed) {
      throw StateError('Command event bus is closed');
    }
    _controller.add(event);
  }

  Future<void> close() => _controller.close();
}

class MutationEventListener {
  MutationEventListener(
    CommandEventBus eventBus, {
    required Future<void> Function(ProjectMutationEvent event) onMutation,
  }) : _subscription = eventBus.events.listen(
         (event) => unawaited(onMutation(event)),
       );

  final StreamSubscription<ProjectMutationEvent> _subscription;

  Future<void> dispose() => _subscription.cancel();
}
