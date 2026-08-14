import 'package:drift/drift.dart';

class VoiceProfiles extends Table {
  TextColumn get characterId => text()();
  TextColumn get displayName => text()();
  TextColumn get language => text()();
  TextColumn get vocalTexture => text()();
  TextColumn get deliveryNotes => text()();
  @override
  Set<Column<Object>> get primaryKey => {characterId};
}

class VoiceReferences extends Table {
  TextColumn get id => text()();
  TextColumn get characterId => text()();
  TextColumn get audioFileId => text()();
  TextColumn get name => text()();
  BoolColumn get primary => boolean().withDefault(const Constant(false))();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

class DialogueLines extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text()();
  TextColumn get sceneId => text()();
  TextColumn get characterId => text()();
  TextColumn get lineText => text()();
  RealColumn get startSeconds => real()();
  RealColumn get durationSeconds => real()();
  TextColumn get subtitleText => text()();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

class DialogueTakes extends Table {
  TextColumn get id => text()();
  TextColumn get lineId => text()();
  TextColumn get audioFileId => text()();
  TextColumn get label => text()();
  BoolColumn get selected => boolean().withDefault(const Constant(false))();
  TextColumn get notes => text().withDefault(const Constant(''))();
  @override
  Set<Column<Object>> get primaryKey => {id};
}
