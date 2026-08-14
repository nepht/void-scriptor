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
    this.onEvent,
  });

  final CommandHistory history;
  final TransactionCoordinator transactionCoordinator;
  final void Function(CommandEvent event)? onEvent;

  Future<void> execute(AppCommand command) async {
    await transactionCoordinator.run(() async {
      await command.execute();
      await history.push(command);
    });
    onEvent?.call(
      CommandEvent(type: CommandEventType.commandExecuted, command: command),
    );
  }

  Future<void> undo() async {
    final commandLabel = history.undoLabel;
    if (commandLabel == null) return;
    await transactionCoordinator.run(history.undo);
    onEvent?.call(
      CommandEvent(
        type: CommandEventType.commandUndone,
        command: _HistoryEventCommand(commandLabel),
      ),
    );
  }

  Future<void> redo() async {
    final commandLabel = history.redoLabel;
    if (commandLabel == null) return;
    await transactionCoordinator.run(history.redo);
    onEvent?.call(
      CommandEvent(
        type: CommandEventType.commandRedone,
        command: _HistoryEventCommand(commandLabel),
      ),
    );
  }
}

class _HistoryEventCommand extends BaseCommand {
  _HistoryEventCommand(String label)
    : super(id: 'history-event', projectId: '', label: label);

  @override
  Future<void> execute() async {}

  @override
  Future<void> undo() async {}
}
