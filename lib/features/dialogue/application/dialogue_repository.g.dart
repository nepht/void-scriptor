// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dialogue_repository.dart';

// ignore_for_file: type=lint
mixin _$DialogueRepositoryMixin on DatabaseAccessor<ProjectDatabase> {
  $VoiceProfilesTable get voiceProfiles => attachedDatabase.voiceProfiles;
  $VoiceReferencesTable get voiceReferences => attachedDatabase.voiceReferences;
  $DialogueLinesTable get dialogueLines => attachedDatabase.dialogueLines;
  $DialogueTakesTable get dialogueTakes => attachedDatabase.dialogueTakes;
  DialogueRepositoryManager get managers => DialogueRepositoryManager(this);
}

class DialogueRepositoryManager {
  final _$DialogueRepositoryMixin _db;
  DialogueRepositoryManager(this._db);
  $$VoiceProfilesTableTableManager get voiceProfiles =>
      $$VoiceProfilesTableTableManager(_db.attachedDatabase, _db.voiceProfiles);
  $$VoiceReferencesTableTableManager get voiceReferences =>
      $$VoiceReferencesTableTableManager(
        _db.attachedDatabase,
        _db.voiceReferences,
      );
  $$DialogueLinesTableTableManager get dialogueLines =>
      $$DialogueLinesTableTableManager(_db.attachedDatabase, _db.dialogueLines);
  $$DialogueTakesTableTableManager get dialogueTakes =>
      $$DialogueTakesTableTableManager(_db.attachedDatabase, _db.dialogueTakes);
}
