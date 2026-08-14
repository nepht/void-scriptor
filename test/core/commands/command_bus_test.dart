import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/commands/app_command.dart';
import 'package:void_scriptor/core/commands/command_bus.dart';
import 'package:void_scriptor/core/commands/command_history.dart';
import 'package:void_scriptor/core/commands/transaction_coordinator.dart';

void main() {
  test(
    'executes inside a transaction and emits an event after history',
    () async {
      final trace = <String>[];
      final history = CommandHistory();
      final bus = CommandBus(
        history: history,
        transactionCoordinator: TraceTransactionCoordinator(trace),
        onPersist: (command) async {
          trace.add('persist:${command.id}');
        },
        onEvent: (event) => trace.add(event.type.name),
      );
      final command = TraceCommand(trace, id: 'rename-1', label: 'Rename');

      await bus.execute(command);

      expect(trace, [
        'begin',
        'execute',
        'persist:rename-1',
        'commit',
        'commandExecuted',
      ]);
      expect(history.canUndo, isTrue);
    },
  );

  test('does not record or emit when command fails', () async {
    final trace = <String>[];
    final history = CommandHistory();
    final bus = CommandBus(
      history: history,
      transactionCoordinator: TraceTransactionCoordinator(trace),
      onPersist: (command) async {
        trace.add('persist:${command.id}');
      },
      onEvent: (event) => trace.add(event.type.name),
    );
    final command = TraceCommand(
      trace,
      id: 'broken-1',
      label: 'Broken',
      shouldFail: true,
    );

    await expectLater(bus.execute(command), throwsStateError);

    expect(trace, ['begin', 'execute', 'rollback']);
    expect(history.canUndo, isFalse);
  });
}

class TraceTransactionCoordinator implements TransactionCoordinator {
  TraceTransactionCoordinator(this.trace);

  final List<String> trace;

  @override
  Future<T> run<T>(Future<T> Function() action) async {
    trace.add('begin');
    try {
      final result = await action();
      trace.add('commit');
      return result;
    } catch (_) {
      trace.add('rollback');
      rethrow;
    }
  }
}

class TraceCommand extends BaseCommand {
  TraceCommand(
    this.trace, {
    required super.id,
    required super.label,
    this.shouldFail = false,
  }) : super(projectId: 'project-1');

  final List<String> trace;
  final bool shouldFail;

  @override
  Future<void> execute() async {
    trace.add('execute');
    if (shouldFail) throw StateError('command failed');
  }

  @override
  Future<void> undo() async {}
}
