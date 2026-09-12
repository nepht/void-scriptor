enum WorkspaceType { novel, character }

enum LinkMode { reference, snapshot, fork }

class NovelCharacterLink {
  NovelCharacterLink({
    required this.linkId,
    required this.novelWorkspaceId,
    required this.characterWorkspaceId,
    required this.characterId,
    required this.mode,
    required this.role,
    required this.visibility,
    required this.createdAt,
    required this.updatedAt,
  }) : owner = WorkspaceType.novel {
    if (linkId.trim().isEmpty) {
      throw ArgumentError.value(linkId, 'linkId');
    }
    if (novelWorkspaceId.trim().isEmpty) {
      throw ArgumentError.value(novelWorkspaceId, 'novelWorkspaceId');
    }
    if (characterWorkspaceId.trim().isEmpty) {
      throw ArgumentError.value(characterWorkspaceId, 'characterWorkspaceId');
    }
    if (characterId.trim().isEmpty) {
      throw ArgumentError.value(characterId, 'characterId');
    }
    if (novelWorkspaceId == characterWorkspaceId) {
      throw ArgumentError('Novel and Character workspace IDs must differ.');
    }
    if (role.trim().isEmpty) {
      throw ArgumentError.value(role, 'role');
    }
    if (visibility.trim().isEmpty) {
      throw ArgumentError.value(visibility, 'visibility');
    }
  }

  factory NovelCharacterLink.create({
    required String linkId,
    required String novelWorkspaceId,
    required String characterWorkspaceId,
    required String characterId,
    required String role,
    required String visibility,
    LinkMode mode = LinkMode.reference,
    DateTime? now,
  }) {
    final timestamp = now ?? DateTime.now().toUtc();
    return NovelCharacterLink(
      linkId: linkId,
      novelWorkspaceId: novelWorkspaceId,
      characterWorkspaceId: characterWorkspaceId,
      characterId: characterId,
      mode: mode,
      role: role,
      visibility: visibility,
      createdAt: timestamp,
      updatedAt: timestamp,
    );
  }

  factory NovelCharacterLink.fromJson(Map<String, dynamic> json) {
    final mode = switch (json['link_mode'] as String?) {
      'reference' => LinkMode.reference,
      'snapshot' => LinkMode.snapshot,
      'fork' => LinkMode.fork,
      final value => throw ArgumentError.value(value, 'link_mode'),
    };
    if (json['owner'] != 'novel') {
      throw ArgumentError.value(json['owner'], 'owner');
    }
    return NovelCharacterLink(
      linkId: json['link_id'] as String,
      novelWorkspaceId: json['novel_workspace_id'] as String,
      characterWorkspaceId: json['character_workspace_id'] as String,
      characterId: json['character_id'] as String,
      mode: mode,
      role: json['role'] as String,
      visibility: json['visibility'] as String,
      createdAt: _parseTimestamp(json['created_at'], 'created_at'),
      updatedAt: _parseTimestamp(json['updated_at'], 'updated_at'),
    );
  }

  static DateTime _parseTimestamp(Object? value, String field) {
    final parsed = value is String ? DateTime.tryParse(value) : null;
    if (parsed == null) {
      throw FormatException(
        'Invalid $field timestamp in novel-character link',
        value,
      );
    }
    return parsed;
  }

  final String linkId;
  final String novelWorkspaceId;
  final String characterWorkspaceId;
  final String characterId;
  final WorkspaceType owner;
  final LinkMode mode;
  final String role;
  final String visibility;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
    'link_id': linkId,
    'novel_workspace_id': novelWorkspaceId,
    'character_workspace_id': characterWorkspaceId,
    'character_id': characterId,
    'owner': 'novel',
    'link_mode': switch (mode) {
      LinkMode.reference => 'reference',
      LinkMode.snapshot => 'snapshot',
      LinkMode.fork => 'fork',
    },
    'role': role,
    'visibility': visibility,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}
