import 'package:uuid/uuid.dart';

import '../../../core/commands/app_command.dart';
import '../../../features/project_resilience/application/command_history_repository.dart';
import '../../assets/domain/asset_relation_type.dart';
import '../domain/asset_relation.dart';
import '../domain/relation_repository.dart';

class RelationCommand extends BaseCommand {
  RelationCommand.create({
    required String id,
    required String projectId,
    required RelationRepository repository,
    required String sourceAssetId,
    required String targetAssetId,
    required AssetRelationType type,
    DateTime? createdAt,
  }) : this._(
         id: id,
         projectId: projectId,
         repository: repository,
         relation: AssetRelation(
           id: const Uuid().v4(),
           projectId: projectId,
           sourceAssetId: sourceAssetId,
           targetAssetId: targetAssetId,
           type: type,
           createdAt: createdAt ?? DateTime.now().toUtc(),
         ),
         createRelation: true,
       );

  RelationCommand.delete({
    required String id,
    required String projectId,
    required RelationRepository repository,
    required AssetRelation relation,
  }) : this._(
         id: id,
         projectId: projectId,
         repository: repository,
         relation: relation,
         createRelation: false,
       );

  RelationCommand._({
    required super.id,
    required super.projectId,
    required this.repository,
    required this.relation,
    required this.createRelation,
  }) : super(label: createRelation ? 'Create relation' : 'Delete relation');

  factory RelationCommand.fromRecord(
    CommandHistoryRecord record,
    RelationRepository repository,
  ) {
    final payload = record.payload;
    final relation = _relationFromPayload(payload['relation']! as Map);
    return RelationCommand._(
      id: record.id,
      projectId: record.projectId,
      repository: repository,
      relation: relation,
      createRelation: payload['operation'] == 'create',
    );
  }

  final RelationRepository repository;
  final AssetRelation relation;
  final bool createRelation;

  @override
  String get commandType =>
      createRelation ? 'relation.create' : 'relation.delete';

  @override
  Map<String, Object?> get payload => {
    'operation': createRelation ? 'create' : 'delete',
    'relation': _relationToPayload(relation),
  };

  @override
  Map<String, Object?> get undoPayload => {
    'operation': createRelation ? 'delete' : 'create',
    'relation': _relationToPayload(relation),
  };

  @override
  Future<void> execute() => _apply(createRelation);

  @override
  Future<void> undo() => _apply(!createRelation);

  @override
  Future<void> redo() => _apply(createRelation);

  Future<void> _apply(bool create) async {
    if (relation.projectId != projectId ||
        relation.sourceAssetId == relation.targetAssetId) {
      throw StateError('Invalid relation for the active project.');
    }
    if (create) {
      await repository.create(relation);
    } else {
      await repository.delete(relation.id);
    }
  }

  static Map<String, Object?> _relationToPayload(AssetRelation relation) => {
    'id': relation.id,
    'projectId': relation.projectId,
    'sourceAssetId': relation.sourceAssetId,
    'targetAssetId': relation.targetAssetId,
    'type': relation.type.value,
    'createdAt': relation.createdAt.toIso8601String(),
  };

  static AssetRelation _relationFromPayload(Map payload) => AssetRelation(
    id: payload['id'] as String,
    projectId: payload['projectId'] as String,
    sourceAssetId: payload['sourceAssetId'] as String,
    targetAssetId: payload['targetAssetId'] as String,
    type: AssetRelationType.values.firstWhere(
      (type) => type.value == payload['type'],
      orElse: () => AssetRelationType.relatedTo,
    ),
    createdAt: DateTime.parse(payload['createdAt'] as String),
  );
}
