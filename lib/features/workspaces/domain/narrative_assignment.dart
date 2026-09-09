/// Backlog `docs/backlog/character-roles-support.json` phase_one vocabulary.
/// Canonical mapping: steps 145.25/145.26 (character linking + novel-specific
/// state). This domain layer stays storage-agnostic; persistence slices map
/// these values onto existing homes (`novel_character_links` v55,
/// `character_novel_states` v59) or a future dedicated table with a guarded
/// migration.
///
/// Principles (backlog `principles`): one character identity — roles attach to
/// assignments, never split a profile; optional fields default to unspecified.
library;

/// Where a character stands in one novel/story: protagonist, antagonist,
/// supporting, or background. Multiple roles are allowed on one assignment.
enum NarrativeRole {
  protagonist('protagonist'),
  antagonist('antagonist'),
  supporting('supporting'),
  background('background');

  const NarrativeRole(this.wireName);

  /// Stable storage/wire token.
  final String wireName;

  static NarrativeRole fromWire(String value) {
    for (final role in NarrativeRole.values) {
      if (role.wireName == value) {
        return role;
      }
    }
    throw ArgumentError.value(value, 'roles', 'Unknown narrative role');
  }
}

/// How much narrative weight one character carries in one novel.
enum NarrativeImportance {
  major('major'),
  supporting('supporting'),
  minor('minor'),
  unspecified('unspecified');

  const NarrativeImportance(this.wireName);

  final String wireName;

  static NarrativeImportance fromWire(String value) {
    for (final candidate in NarrativeImportance.values) {
      if (candidate.wireName == value) {
        return candidate;
      }
    }
    throw ArgumentError.value(value, 'importance', 'Unknown importance');
  }
}

/// Whether one character serves as a point-of-view carrier in one novel.
enum NarrativePov {
  yes('yes'),
  no('no'),
  unspecified('unspecified');

  const NarrativePov(this.wireName);

  final String wireName;

  static NarrativePov fromWire(String value) {
    for (final candidate in NarrativePov.values) {
      if (candidate.wireName == value) {
        return candidate;
      }
    }
    throw ArgumentError.value(value, 'pov', 'Unknown POV value');
  }
}

/// Per-novel narrative assignment of one character. One character keeps a
/// single profile; this value object is keyed by (novel, character) so the
/// same character holds independent assignments in different novels without
/// cross-contamination.
class NarrativeAssignment {
  /// Runtime (non-const) validation mirrors the repository convention used by
  /// [NovelCharacterLink]: blank coordinates throw [ArgumentError] instead of
  /// a const-eval assert (Dart asserts cannot call `isNotEmpty`).
  NarrativeAssignment({
    required this.novelWorkspaceId,
    required this.characterId,
    this.roles = const <NarrativeRole>{},
    this.importance = NarrativeImportance.unspecified,
    this.pov = NarrativePov.unspecified,
  }) {
    if (novelWorkspaceId.trim().isEmpty) {
      throw ArgumentError.value(novelWorkspaceId, 'novelWorkspaceId');
    }
    if (characterId.trim().isEmpty) {
      throw ArgumentError.value(characterId, 'characterId');
    }
  }

  /// Novel/story workspace the assignment belongs to.
  final String novelWorkspaceId;

  /// Character (entity) id the assignment describes.
  final String characterId;

  /// Narrative roles. Multiple roles are allowed.
  final Set<NarrativeRole> roles;

  /// Optional importance; defaults to [NarrativeImportance.unspecified].
  final NarrativeImportance importance;

  /// Optional POV flag; defaults to [NarrativePov.unspecified].
  final NarrativePov pov;

  /// Returns a copy with the given fields replaced; unspecified-named fields
  /// keep their current value.
  NarrativeAssignment copyWith({
    Set<NarrativeRole>? roles,
    NarrativeImportance? importance,
    NarrativePov? pov,
  }) => NarrativeAssignment(
    novelWorkspaceId: novelWorkspaceId,
    characterId: characterId,
    roles: roles ?? this.roles,
    importance: importance ?? this.importance,
    pov: pov ?? this.pov,
  );

  Map<String, dynamic> toJson() {
    final roleNames = roles.map((role) => role.wireName).toList()..sort();
    return <String, dynamic>{
      'novel_workspace_id': novelWorkspaceId,
      'character_id': characterId,
      'roles': roleNames,
      'importance': importance.wireName,
      'pov': pov.wireName,
    };
  }

  factory NarrativeAssignment.fromJson(Map<String, dynamic> json) {
    final rawRoles = json['roles'];
    final roles = <NarrativeRole>{};
    if (rawRoles is List) {
      // BUG-11 (hunt-run157): one unknown/malformed role entry (realistic
      // vector: version-skewed portable import) must not abort the whole
      // decode; skip it so the valid entries stay adoptable.
      for (final entry in rawRoles) {
        if (entry is! String) continue;
        try {
          roles.add(NarrativeRole.fromWire(entry));
        } on ArgumentError {
          // Unknown role token: keep the assignment without it.
        }
      }
    }
    return NarrativeAssignment(
      novelWorkspaceId: json['novel_workspace_id'] as String,
      characterId: json['character_id'] as String,
      roles: roles,
      importance: _tolerantEnum(
        json['importance'],
        NarrativeImportance.fromWire,
        NarrativeImportance.unspecified,
      ),
      pov: _tolerantEnum(
        json['pov'],
        NarrativePov.fromWire,
        NarrativePov.unspecified,
      ),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NarrativeAssignment &&
          other.novelWorkspaceId == novelWorkspaceId &&
          other.characterId == characterId &&
          _setEquals(other.roles, roles) &&
          other.importance == importance &&
          other.pov == pov;

  @override
  int get hashCode => Object.hash(
    novelWorkspaceId,
    characterId,
    Object.hashAllUnordered(roles),
    importance,
    pov,
  );

  @override
  String toString() =>
      'NarrativeAssignment(novel: $novelWorkspaceId, character: '
      '$characterId, roles: $roles, importance: ${importance.wireName}, '
      'pov: ${pov.wireName})';
}

bool _setEquals(Set<Object?> left, Set<Object?> right) {
  if (left.length != right.length) {
    return false;
  }
  for (final value in left) {
    if (!right.contains(value)) {
      return false;
    }
  }
  return true;
}

/// BUG-11 (hunt-run157) shared tolerant decode: an unknown or non-string
/// optional enum token falls back to [fallback] ("no explicit value")
/// instead of aborting the whole decode.
T _tolerantEnum<T>(Object? value, T Function(String) fromWire, T fallback) {
  if (value is! String) {
    return fallback;
  }
  try {
    return fromWire(value);
  } on ArgumentError {
    return fallback;
  }
}

/// Kind of support one character provides to another character or group
/// within one story context.
enum SupportType {
  travelCompanion('travel_companion'),
  mentor('mentor'),
  informant('informant'),
  protector('protector'),
  supporter('supporter');

  const SupportType(this.wireName);

  final String wireName;

  static SupportType fromWire(String value) {
    for (final type in SupportType.values) {
      if (type.wireName == value) {
        return type;
      }
    }
    throw ArgumentError.value(value, 'type', 'Unknown support type');
  }
}

/// How long a support relationship holds.
enum SupportDuration {
  permanent('permanent'),
  temporary('temporary'),
  recurring('recurring'),
  unspecified('unspecified');

  const SupportDuration(this.wireName);

  final String wireName;

  static SupportDuration fromWire(String value) {
    for (final candidate in SupportDuration.values) {
      if (candidate.wireName == value) {
        return candidate;
      }
    }
    throw ArgumentError.value(value, 'duration', 'Unknown duration');
  }
}

/// Current state of a support relationship.
enum SupportStatus {
  active('active'),
  separated('separated'),
  terminated('terminated'),
  unspecified('unspecified');

  const SupportStatus(this.wireName);

  final String wireName;

  static SupportStatus fromWire(String value) {
    for (final candidate in SupportStatus.values) {
      if (candidate.wireName == value) {
        return candidate;
      }
    }
    throw ArgumentError.value(value, 'status', 'Unknown support status');
  }
}

/// One support relationship: source character supports one character or group
/// within one story (novel) context. Duration/status changes must not touch
/// importance or POV (acceptance: 'Duration changes do not change importance
/// or POV') — structurally true here because those fields live on
/// [NarrativeAssignment], not on this relationship.
class SupportRelationship {
  /// Runtime (non-const) validation mirrors the repository convention used by
  /// [NovelCharacterLink]: blank coordinates throw [ArgumentError].
  SupportRelationship({
    required this.sourceCharacterId,
    required this.supportedId,
    required this.storyNovelWorkspaceId,
    required this.type,
    this.duration = SupportDuration.unspecified,
    this.status = SupportStatus.unspecified,
    this.purpose,
    this.separationReason,
  }) {
    if (sourceCharacterId.trim().isEmpty) {
      throw ArgumentError.value(sourceCharacterId, 'sourceCharacterId');
    }
    if (supportedId.trim().isEmpty) {
      throw ArgumentError.value(supportedId, 'supportedId');
    }
    if (storyNovelWorkspaceId.trim().isEmpty) {
      throw ArgumentError.value(storyNovelWorkspaceId, 'storyNovelWorkspaceId');
    }
  }

  final String sourceCharacterId;
  final String supportedId;
  final String storyNovelWorkspaceId;
  final SupportType type;
  final SupportDuration duration;
  final SupportStatus status;

  /// Optional purpose of the support.
  final String? purpose;

  /// Optional reason recorded when the support separates/ends.
  final String? separationReason;

  /// Returns a copy with the given fields replaced; unspecified-named fields
  /// keep their current value. Changing [duration] never touches importance
  /// or POV because those live on [NarrativeAssignment], not here.
  ///
  /// Nullable optional fields ([purpose], [separationReason]) cannot be
  /// cleared through a null argument (null means "keep"); pass the matching
  /// `clearX` flag instead (hunt-run157 BUG-10). A value passed together with
  /// its clear flag wins.
  SupportRelationship copyWith({
    SupportType? type,
    SupportDuration? duration,
    SupportStatus? status,
    String? purpose,
    String? separationReason,
    bool clearPurpose = false,
    bool clearSeparationReason = false,
  }) => SupportRelationship(
    sourceCharacterId: sourceCharacterId,
    supportedId: supportedId,
    storyNovelWorkspaceId: storyNovelWorkspaceId,
    type: type ?? this.type,
    duration: duration ?? this.duration,
    status: status ?? this.status,
    purpose: clearPurpose ? purpose : (purpose ?? this.purpose),
    separationReason: clearSeparationReason
        ? separationReason
        : (separationReason ?? this.separationReason),
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'source_character_id': sourceCharacterId,
    'supported_id': supportedId,
    'story_novel_workspace_id': storyNovelWorkspaceId,
    'type': type.wireName,
    'duration': duration.wireName,
    'status': status.wireName,
    'purpose': purpose,
    'separation_reason': separationReason,
  };

  factory SupportRelationship.fromJson(Map<String, dynamic> json) {
    return SupportRelationship(
      sourceCharacterId: json['source_character_id'] as String,
      supportedId: json['supported_id'] as String,
      storyNovelWorkspaceId: json['story_novel_workspace_id'] as String,
      type: SupportType.fromWire(json['type'] as String),
      duration: _tolerantEnum(
        json['duration'],
        SupportDuration.fromWire,
        SupportDuration.unspecified,
      ),
      status: _tolerantEnum(
        json['status'],
        SupportStatus.fromWire,
        SupportStatus.unspecified,
      ),
      // BUG-11 (hunt-run157): a non-string optional payload (version-skewed
      // import) must not abort the whole decode; drop it instead.
      purpose: json['purpose'] is String ? json['purpose'] as String : null,
      separationReason: json['separation_reason'] is String
          ? json['separation_reason'] as String
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SupportRelationship &&
          other.sourceCharacterId == sourceCharacterId &&
          other.supportedId == supportedId &&
          other.storyNovelWorkspaceId == storyNovelWorkspaceId &&
          other.type == type &&
          other.duration == duration &&
          other.status == status &&
          other.purpose == purpose &&
          other.separationReason == separationReason;

  @override
  int get hashCode => Object.hash(
    sourceCharacterId,
    supportedId,
    storyNovelWorkspaceId,
    type,
    duration,
    status,
    purpose,
    separationReason,
  );

  @override
  String toString() =>
      'SupportRelationship(source: $sourceCharacterId, '
      'supported: $supportedId, story: $storyNovelWorkspaceId, '
      'type: ${type.wireName}, duration: ${duration.wireName}, '
      'status: ${status.wireName})';
}
