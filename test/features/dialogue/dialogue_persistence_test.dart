import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/dialogue/application/dialogue_repository.dart';
import 'package:void_scriptor/features/dialogue/domain/dialogue_models.dart';

void main() {
  test(
    'dialogue takes, selected voice take, profile and reference survive restart',
    () async {
      final root = await Directory.systemTemp.createTemp('dialogue-voice-');
      addTearDown(() => root.delete(recursive: true));
      final paths = ProjectPaths(rootDirectory: root);
      await (await paths.project('project-dialogue')).create(recursive: true);
      final dbPath = (await paths.database('project-dialogue')).path;
      final service = ProjectDatabaseService();
      final database = await service.open(dbPath);
      final repository = DialogueRepository(database);

      await repository.saveVoiceProfile(
        const VoiceProfileModel(
          characterId: 'qowner',
          displayName: 'Qowner Voice',
          language: 'id-ID',
          vocalTexture: 'low, calm, restrained',
          deliveryNotes: 'Emotion rises only at decisive moments.',
        ),
      );
      await repository.saveVoiceReference(
        const VoiceReferenceModel(
          id: 'voice-ref-qowner',
          characterId: 'qowner',
          audioFileId: 'audio-qowner-voice',
          name: 'Qowner reference take',
          primary: true,
        ),
      );
      await repository.saveDialogueLine(
        const DialogueLineModel(
          id: 'line-001',
          projectId: 'project-dialogue',
          sceneId: 'scene-8',
          characterId: 'qowner',
          text: 'Aku tidak akan menyerahkan Void Cube.',
          startSeconds: 12,
          durationSeconds: 3.2,
          subtitleText: 'Aku tidak akan menyerahkan Void Cube.',
        ),
      );
      await repository.saveDialogueTakes(const [
        DialogueTakeModel(
          id: 'take-a',
          lineId: 'line-001',
          audioFileId: 'audio-a',
          label: 'Controlled',
          selected: false,
        ),
        DialogueTakeModel(
          id: 'take-b',
          lineId: 'line-001',
          audioFileId: 'audio-b',
          label: 'Emotional',
          selected: true,
        ),
        DialogueTakeModel(
          id: 'take-c',
          lineId: 'line-001',
          audioFileId: 'audio-c',
          label: 'Whisper',
          selected: false,
        ),
      ]);
      await database.close();

      final second = await service.open(dbPath);
      addTearDown(second.close);
      final restored = DialogueRepository(second);
      expect(second.schemaVersion, 38);
      expect((await restored.getVoiceProfile('qowner'))?.language, 'id-ID');
      expect(
        (await restored.primaryVoiceReference('qowner'))?.audioFileId,
        'audio-qowner-voice',
      );
      expect((await restored.getDialogueLine('line-001'))?.startSeconds, 12);
      expect(
        (await restored.takesForLine(
          'line-001',
        )).where((take) => take.selected).single.id,
        'take-b',
      );
    },
  );
}
