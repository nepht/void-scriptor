import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/commands/app_command.dart';
import 'package:void_scriptor/core/commands/command_type_registry.dart';
import 'package:void_scriptor/features/project_resilience/application/command_history_repository.dart';

void main() {
  test('resolves stable command types and rejects unknown types', () {
    final registry = CommandTypeRegistry();
    registry.register('asset.rename', (record) => FakeCommand(record.label));
    final record = CommandHistoryRecord(
      id: 'cmd-1',
      projectId: 'p1',
      commandType: 'asset.rename',
      label: 'Rename Qowner',
      payload: {'name': 'Void Scriptor'},
      undoPayload: {'name': 'Qowner'},
      sequence: 1,
      source: 'user',
      status: CommandHistoryStatus.applied,
      createdAt: DateTime.utc(2026),
    );

    expect(registry.create(record).label, 'Rename Qowner');
    expect(
      () => registry.create(record.copyWith(commandType: 'future.unknown')),
      throwsA(isA<UnsupportedError>()),
    );
  });
}

class FakeCommand extends BaseCommand {
  FakeCommand(String label) : super(id: 'fake', projectId: 'p1', label: label);

  @override
  Future<void> execute() async {}

  @override
  Future<void> undo() async {}
}

extension on CommandHistoryRecord {
  CommandHistoryRecord copyWith({String? commandType}) => CommandHistoryRecord(
    id: id,
    projectId: projectId,
    commandType: commandType ?? this.commandType,
    label: label,
    payload: payload,
    undoPayload: undoPayload,
    sequence: sequence,
    source: source,
    status: status,
    createdAt: createdAt,
  );
}
