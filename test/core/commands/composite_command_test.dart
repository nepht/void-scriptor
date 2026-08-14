import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/commands/app_command.dart';
import 'package:void_scriptor/core/commands/composite_command.dart';

void main() {
  test('undoes composite commands in reverse order', () async {
    final trace = <String>[];
    final composite = CompositeCommand(
      id: 'add-scene-character',
      projectId: 'project-1',
      label: 'Add Character to Scene',
      commands: [
        TraceCommand(trace, 'create-instance'),
        TraceCommand(trace, 'add-relation'),
        TraceCommand(trace, 'add-clip'),
      ],
    );

    await composite.execute();
    await composite.undo();
    await composite.redo();

    expect(trace, [
      'execute:create-instance',
      'execute:add-relation',
      'execute:add-clip',
      'undo:add-clip',
      'undo:add-relation',
      'undo:create-instance',
      'redo:create-instance',
      'redo:add-relation',
      'redo:add-clip',
    ]);
  });
}

class TraceCommand extends BaseCommand {
  TraceCommand(this.trace, this.name)
    : super(id: name, projectId: 'project-1', label: name);

  final List<String> trace;
  final String name;

  @override
  Future<void> execute() async => trace.add('execute:$name');

  @override
  Future<void> undo() async => trace.add('undo:$name');

  @override
  Future<void> redo() async => trace.add('redo:$name');
}
