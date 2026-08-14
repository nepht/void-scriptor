import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/commands/app_command.dart';
import 'package:void_scriptor/core/commands/command_history.dart';

void main() {
  test('executes command and exposes undo metadata', () async {
    var value = 0;
    final history = CommandHistory();

    await history.execute(
      TestCommand(
        label: 'Increment',
        executeAction: () => value += 1,
        reverseAction: () => value -= 1,
      ),
    );

    expect(value, 1);
    expect(history.canUndo, isTrue);
    expect(history.canRedo, isFalse);
    expect(history.undoLabel, 'Increment');
  });

  test('undoes and redoes the latest command', () async {
    var value = 0;
    final history = CommandHistory();
    final command = TestCommand(
      label: 'Increment',
      executeAction: () => value += 1,
      reverseAction: () => value -= 1,
    );

    await history.execute(command);
    await history.undo();
    expect(value, 0);
    expect(history.canUndo, isFalse);
    expect(history.canRedo, isTrue);
    expect(history.redoLabel, 'Increment');

    await history.redo();
    expect(value, 1);
    expect(history.canUndo, isTrue);
    expect(history.canRedo, isFalse);
  });

  test('new command clears redo history and respects capacity', () async {
    var value = 0;
    final history = CommandHistory(capacity: 2);

    Future<void> increment(String label) => history.execute(
      TestCommand(
        label: label,
        executeAction: () => value += 1,
        reverseAction: () => value -= 1,
      ),
    );

    await increment('One');
    await increment('Two');
    await history.undo();
    await increment('Three');

    expect(value, 2);
    expect(history.canRedo, isFalse);
    expect(history.undoLabel, 'Three');

    await history.undo();
    await history.undo();
    expect(value, 0);
    expect(history.canUndo, isFalse);
  });
}

class TestCommand extends BaseCommand {
  TestCommand({
    required super.label,
    required this.executeAction,
    required this.reverseAction,
  }) : super(id: 'test-command', projectId: 'test-project');

  final void Function() executeAction;
  final void Function() reverseAction;

  @override
  Future<void> execute() async => executeAction();

  @override
  Future<void> undo() async => reverseAction();
}
