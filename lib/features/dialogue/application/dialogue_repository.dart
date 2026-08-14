import 'package:drift/drift.dart';
import '../../../database/project/project_database.dart';
import '../../../database/project/tables/dialogue.dart';
import '../domain/dialogue_models.dart' as domain;
part 'dialogue_repository.g.dart';

@DriftAccessor(
  tables: [VoiceProfiles, VoiceReferences, DialogueLines, DialogueTakes],
)
class DialogueRepository extends DatabaseAccessor<ProjectDatabase>
    with _$DialogueRepositoryMixin {
  DialogueRepository(super.db);
  Future<void> saveVoiceProfile(domain.VoiceProfileModel v) =>
      into(voiceProfiles).insertOnConflictUpdate(
        VoiceProfilesCompanion.insert(
          characterId: v.characterId,
          displayName: v.displayName,
          language: v.language,
          vocalTexture: v.vocalTexture,
          deliveryNotes: v.deliveryNotes,
        ),
      );
  Future<domain.VoiceProfileModel?> getVoiceProfile(String id) async {
    final r = await (select(
      voiceProfiles,
    )..where((x) => x.characterId.equals(id))).getSingleOrNull();
    return r == null
        ? null
        : domain.VoiceProfileModel(
            characterId: r.characterId,
            displayName: r.displayName,
            language: r.language,
            vocalTexture: r.vocalTexture,
            deliveryNotes: r.deliveryNotes,
          );
  }

  Future<void> saveVoiceReference(domain.VoiceReferenceModel v) async {
    await transaction(() async {
      if (v.primary) {
        await (update(voiceReferences)
              ..where((x) => x.characterId.equals(v.characterId)))
            .write(const VoiceReferencesCompanion(primary: Value(false)));
      }
      await into(voiceReferences).insertOnConflictUpdate(
        VoiceReferencesCompanion.insert(
          id: v.id,
          characterId: v.characterId,
          audioFileId: v.audioFileId,
          name: v.name,
          primary: Value(v.primary),
        ),
      );
    });
  }

  Future<domain.VoiceReferenceModel?> primaryVoiceReference(String id) async {
    final r =
        await (select(voiceReferences)
              ..where((x) => x.characterId.equals(id) & x.primary.equals(true)))
            .getSingleOrNull();
    return r == null
        ? null
        : domain.VoiceReferenceModel(
            id: r.id,
            characterId: r.characterId,
            audioFileId: r.audioFileId,
            name: r.name,
            primary: r.primary,
          );
  }

  Future<void> saveDialogueLine(domain.DialogueLineModel v) =>
      into(dialogueLines).insertOnConflictUpdate(
        DialogueLinesCompanion.insert(
          id: v.id,
          projectId: v.projectId,
          sceneId: v.sceneId,
          characterId: v.characterId,
          lineText: v.text,
          startSeconds: v.startSeconds,
          durationSeconds: v.durationSeconds,
          subtitleText: v.subtitleText,
        ),
      );
  Future<domain.DialogueLineModel?> getDialogueLine(String id) async {
    final r = await (select(
      dialogueLines,
    )..where((x) => x.id.equals(id))).getSingleOrNull();
    return r == null
        ? null
        : domain.DialogueLineModel(
            id: r.id,
            projectId: r.projectId,
            sceneId: r.sceneId,
            characterId: r.characterId,
            text: r.lineText,
            startSeconds: r.startSeconds,
            durationSeconds: r.durationSeconds,
            subtitleText: r.subtitleText,
          );
  }

  Future<void> saveDialogueTakes(List<domain.DialogueTakeModel> values) async {
    await transaction(() async {
      for (final v in values) {
        if (v.selected) {
          await (update(dialogueTakes)..where((x) => x.lineId.equals(v.lineId)))
              .write(const DialogueTakesCompanion(selected: Value(false)));
        }
        await into(dialogueTakes).insertOnConflictUpdate(
          DialogueTakesCompanion.insert(
            id: v.id,
            lineId: v.lineId,
            audioFileId: v.audioFileId,
            label: v.label,
            selected: Value(v.selected),
            notes: Value(v.notes),
          ),
        );
      }
    });
  }

  Future<List<domain.DialogueTakeModel>> takesForLine(String id) async {
    final rows = await (select(
      dialogueTakes,
    )..where((x) => x.lineId.equals(id))).get();
    return [
      for (final r in rows)
        domain.DialogueTakeModel(
          id: r.id,
          lineId: r.lineId,
          audioFileId: r.audioFileId,
          label: r.label,
          selected: r.selected,
          notes: r.notes,
        ),
    ];
  }
}
