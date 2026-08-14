import 'app_command.dart';
import 'command_history.dart';
import 'transaction_coordinator.dart';

enum CommandEventType { commandExecuted, commandUndone, commandRedone }

class CommandEvent {
  const CommandEvent({required this.type, required this.command});

  final CommandEventType type;
  final AppCommand command;
}

class CommandBus {
  CommandBus({
    required this.history,
    required this.transactionCoordinator,
    this.onPersist,
    this.onUndoPersist,
    this.onRedoPersist,
    this.onEvent,
  });

  final CommandHistory history;
  final TransactionCoordinator transactionCoordinator;
  final Future<void> Function(AppCommand command)? onPersist;
  final Future<void> Function(AppCommand command)? onUndoPersist;
  final Future<void> Function(AppCommand command)? onRedoPersist;
  final void Function(CommandEvent event)? onEvent;

  Future<void> execute(AppCommand command) async {
    await transactionCoordinator.run(() async {
      await command.execute();
      await onPersist?.call(command);
      await history.push(command);
    });
    onEvent?.call(
      CommandEvent(type: CommandEventType.commandExecuted, command: command),
    );
  }

  Future<void> undo() async {
    final command = history.undoCommand;
    if (command == null) return;
    await transactionCoordinator.run(() async {
      await history.undo();
      await onUndoPersist?.call(command);
    });
    onEvent?.call(
      CommandEvent(type: CommandEventType.commandUndone, command: command),
    );
  }

  Future<void> redo() async {
    final command = history.redoCommand;
    if (command == null) return;
    await transactionCoordinator.run(() async {
      await history.redo();
      await onRedoPersist?.call(command);
    });
    onEvent?.call(
      CommandEvent(type: CommandEventType.commandRedone, command: command),
    );
  }
}
