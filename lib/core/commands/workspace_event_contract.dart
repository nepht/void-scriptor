enum WorkspaceEventName {
  linkCreated('ws.link.created'),
  linkUnlinked('ws.link.unlinked'),
  linkModeChanged('ws.link.mode_changed'),
  projectionInvalidated('ws.projection.invalidated'),
  characterArchived('ws.character.archived'),
  characterDeleted('ws.character.deleted');

  const WorkspaceEventName(this.wireName);

  final String wireName;

  static WorkspaceEventName parse(String value) {
    for (final name in values) {
      if (name.wireName == value) return name;
    }
    throw FormatException('Unknown workspace event name: $value');
  }
}

class WorkspaceContractEvent {
  const WorkspaceContractEvent({
    required this.name,
    required this.projectId,
    required this.entityIds,
  });

  static const schema = 'ws-events/v1';

  final WorkspaceEventName name;
  final String projectId;
  final List<String> entityIds;

  factory WorkspaceContractEvent.fromJson(Map<String, Object?> json) {
    if (json['schema'] != schema) {
      throw FormatException(
        'Unsupported workspace event schema: ${json['schema']}',
      );
    }
    final projectId = json['project_id'];
    final entityIds = json['entity_ids'];
    if (projectId is! String || projectId.trim().isEmpty) {
      throw const FormatException('Workspace event project_id is required');
    }
    if (entityIds is! List ||
        entityIds.isEmpty ||
        entityIds.any((id) => id is! String || id.trim().isEmpty)) {
      throw const FormatException('Workspace event entity_ids are required');
    }
    final name = json['name'];
    if (name is! String) {
      throw const FormatException('Workspace event name is required');
    }
    return WorkspaceContractEvent(
      name: WorkspaceEventName.parse(name),
      projectId: projectId,
      entityIds: List<String>.unmodifiable(entityIds.cast<String>()),
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'schema': schema,
    'name': name.wireName,
    'project_id': projectId,
    'entity_ids': entityIds,
  };

  @override
  bool operator ==(Object other) =>
      other is WorkspaceContractEvent &&
      other.name == name &&
      other.projectId == projectId &&
      _listEquals(other.entityIds, entityIds);

  @override
  int get hashCode => Object.hash(name, projectId, Object.hashAll(entityIds));
}

bool _listEquals(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
