import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/audio/application/audio_asset_repository.dart';
import 'package:void_scriptor/features/audio/domain/audio_models.dart';

void main() {
  test('SFX ambience and music production metadata survive restart', () async {
    final root = await Directory.systemTemp.createTemp('audio-assets-');
    addTearDown(() => root.delete(recursive: true));
    final paths = ProjectPaths(rootDirectory: root);
    await (await paths.project('p')).create(recursive: true);
    final dbPath = (await paths.database('p')).path;
    final service = ProjectDatabaseService();
    final db = await service.open(dbPath);
    final repo = AudioAssetRepository(db);
    await repo.saveAudioFile(
      const AudioFileModel(
        id: 'audio-portal-1',
        projectId: 'p',
        filePath: 'assets/audio/sfx/portal.wav',
        contentHash: 'hash-1',
        durationSeconds: 2.4,
        sampleRate: 48000,
        channels: 2,
      ),
    );
    await repo.saveSoundEffect(
      const SoundEffectModel(
        assetId: 'sfx-portal',
        projectId: 'p',
        audioFileId: 'audio-portal-1',
        name: 'Void Portal Open',
        category: SoundEffectCategory.voidEffect,
      ),
    );
    await repo.saveSoundEffectVariations(const [
      SoundEffectVariationModel(
        id: 'take-1',
        soundEffectId: 'sfx-portal',
        audioFileId: 'audio-portal-1',
        label: 'Take 01',
        weight: 1,
      ),
    ]);
    await repo.saveAmbience(
      const AmbienceModel(
        assetId: 'amb-beach',
        projectId: 'p',
        name: 'Beach Sunset',
      ),
    );
    await repo.saveAmbienceLayer(
      const AmbienceLayerModel(
        id: 'waves',
        ambienceId: 'amb-beach',
        audioFileId: 'audio-portal-1',
        name: 'Ocean Waves',
        defaultGainDb: -6,
      ),
    );
    await repo.saveAmbienceVariant(
      const AmbienceVariantModel(
        id: 'sunset',
        ambienceId: 'amb-beach',
        name: 'Sunset',
        conditions: 'time=sunset;weather=clear',
      ),
    );
    await repo.saveMusic(
      const MusicCueModel(
        assetId: 'music-qowner',
        projectId: 'p',
        audioFileId: 'audio-portal-1',
        name: 'Qowner Theme',
        mood: MusicMood.emotional,
        bpm: 72,
        musicalKey: 'D minor',
      ),
    );
    await repo.saveMusicSection(
      const MusicSectionModel(
        id: 'main',
        musicId: 'music-qowner',
        name: 'Main Theme',
        startSeconds: 48,
        endSeconds: 90,
        mood: MusicMood.emotional,
      ),
    );
    await db.close();
    final second = await service.open(dbPath);
    addTearDown(second.close);
    final restored = AudioAssetRepository(second);
    expect(second.schemaVersion, 43);
    expect(
      (await restored.getSoundEffect('sfx-portal'))?.category,
      SoundEffectCategory.voidEffect,
    );
    expect(
      (await restored.variationsFor('sfx-portal')).single.label,
      'Take 01',
    );
    expect((await restored.layersFor('amb-beach')).single.defaultGainDb, -6);
    expect(
      (await restored.variantsFor('amb-beach')).single.conditions,
      contains('sunset'),
    );
    expect(
      (await restored.getMusic('music-qowner'))?.mood,
      MusicMood.emotional,
    );
    expect(
      (await restored.sectionsFor('music-qowner')).single.startSeconds,
      48,
    );
  });
}
