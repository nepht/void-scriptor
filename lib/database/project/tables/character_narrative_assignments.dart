import 'package:drift/drift.dart';

/// Persistence homes for backlog `docs/backlog/character-roles-support.json`
/// phase_one (canonical mapping: steps 145.25/145.26). One character keeps a
/// single profile; narrative assignments are keyed per (project, novel,
/// character) so the same character holds independent assignments in
/// different novels without cross-contamination. Enum values persist as the
/// domain `wireName` tokens; multiple roles are stored as one baris with a
/// comma-joined list (no wire token contains a comma).
class CharacterNarrativeAssignments extends Table {
  TextColumn get projectId => text()();
  TextColumn get novelWorkspaceId => text()();
  TextColumn get characterId => text()();

  /// Comma-joined [NarrativeRole] wire tokens; null/empty = no roles yet.
  TextColumn get roles => text().nullable()();

  /// [NarrativeImportance] wire token; null = unspecified.
  TextColumn get importance => text().nullable()();

  /// [NarrativePov] wire token; null = unspecified.
  TextColumn get pov => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {
    projectId,
    novelWorkspaceId,
    characterId,
  };
}

/// One support relationship per (project, source character, supported
/// character/group, story novel). A supports B permanently and C temporarily
/// are two independent rows. Duration and status live only here — editing
/// them physically cannot touch an assignment's importance/POV.
class CharacterSupportRelationships extends Table {
  TextColumn get projectId => text()();
  TextColumn get sourceCharacterId => text()();
  TextColumn get supportedId => text()();
  TextColumn get storyNovelWorkspaceId => text()();

  /// [SupportType] wire token; required for a persisted relationship.
  TextColumn get type => text()();

  /// [SupportDuration] wire token; default unspecified.
  TextColumn get duration =>
      text().withDefault(const Constant('unspecified'))();

  /// [SupportStatus] wire token; default unspecified.
  TextColumn get status => text().withDefault(const Constant('unspecified'))();

  /// Optional purpose of the support.
  TextColumn get purpose => text().nullable()();

  /// Optional reason recorded when the support separates/ends.
  TextColumn get separationReason => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {
    projectId,
    sourceCharacterId,
    supportedId,
    storyNovelWorkspaceId,
  };
}
