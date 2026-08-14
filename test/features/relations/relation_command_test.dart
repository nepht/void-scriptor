import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/assets/domain/asset_relation_type.dart';
import 'package:void_scriptor/features/relations/application/relation_command.dart';
import 'package:void_scriptor/features/relations/domain/asset_relation.dart';
import 'package:void_scriptor/features/relations/domain/relation_repository.dart';
import 'package:void_scriptor/features/project_resilience/application/command_history_repository.dart';

class _Repository implements RelationRepository {
  final items = <String, AssetRelation>{};

  @override
  Future<List<AssetRelation>> outgoing(String id) async =>
      items.values.where((r) => r.sourceAssetId == id).toList();

  @override
  Future<List<AssetRelation>> incoming(String id) async =>
      items.values.where((r) => r.targetAssetId == id).toList();

  @override
  Future<void> create(AssetRelation relation) async =>
      items[relation.id] = relation;

  @override
  Future<void> delete(String id) async => items.remove(id);
}

void main() {
  test(
    'relation command supports execute undo redo and payload hydration',
    () async {
      final repository = _Repository();
      final command = RelationCommand.create(
        id: 'command-1',
        projectId: 'project-1',
        repository: repository,
        sourceAssetId: 'source',
        targetAssetId: 'target',
        type: AssetRelationType.wears,
        createdAt: DateTime.utc(2026),
      );

      await command.execute();
      expect(repository.items, hasLength(1));
      final hydrated = RelationCommand.fromRecord(_record(command), repository);
      await hydrated.undo();
      expect(repository.items, isEmpty);
      await hydrated.redo();
      expect(repository.items.values.single.type, AssetRelationType.wears);
    },
  );

  test('delete command undo restores the exact relation snapshot', () async {
    final repository = _Repository();
    final relation = AssetRelation(
      id: 'relation-1',
      projectId: 'project-1',
      sourceAssetId: 'source',
      targetAssetId: 'target',
      type: AssetRelationType.uses,
      createdAt: DateTime.utc(2026),
    );
    await repository.create(relation);
    final command = RelationCommand.delete(
      id: 'command-2',
      projectId: 'project-1',
      repository: repository,
      relation: relation,
    );

    await command.execute();
    expect(repository.items, isEmpty);
    await command.undo();
    expect(repository.items['relation-1']!.createdAt, relation.createdAt);
    await command.redo();
    expect(repository.items, isEmpty);
  });
}

CommandHistoryRecord _record(RelationCommand command) => CommandHistoryRecord(
  id: command.id,
  projectId: command.projectId,
  commandType: command.commandType,
  label: command.label,
  payload: Map<String, dynamic>.from(command.payload),
  undoPayload: Map<String, dynamic>.from(command.undoPayload),
  sequence: 1,
  source: command.source,
  status: CommandHistoryStatus.applied,
  createdAt: DateTime.utc(2026),
);
