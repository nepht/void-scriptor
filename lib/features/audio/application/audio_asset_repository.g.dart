// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audio_asset_repository.dart';

// ignore_for_file: type=lint
mixin _$AudioAssetRepositoryMixin on DatabaseAccessor<ProjectDatabase> {
  $AudioFilesTable get audioFiles => attachedDatabase.audioFiles;
  $SoundEffectsTable get soundEffects => attachedDatabase.soundEffects;
  $SoundEffectVariationsTable get soundEffectVariations =>
      attachedDatabase.soundEffectVariations;
  $AmbienceAssetsTable get ambienceAssets => attachedDatabase.ambienceAssets;
  $AmbienceLayersTable get ambienceLayers => attachedDatabase.ambienceLayers;
  $AmbienceVariantsTable get ambienceVariants =>
      attachedDatabase.ambienceVariants;
  $MusicCuesTable get musicCues => attachedDatabase.musicCues;
  $MusicSectionsTable get musicSections => attachedDatabase.musicSections;
  AudioAssetRepositoryManager get managers => AudioAssetRepositoryManager(this);
}

class AudioAssetRepositoryManager {
  final _$AudioAssetRepositoryMixin _db;
  AudioAssetRepositoryManager(this._db);
  $$AudioFilesTableTableManager get audioFiles =>
      $$AudioFilesTableTableManager(_db.attachedDatabase, _db.audioFiles);
  $$SoundEffectsTableTableManager get soundEffects =>
      $$SoundEffectsTableTableManager(_db.attachedDatabase, _db.soundEffects);
  $$SoundEffectVariationsTableTableManager get soundEffectVariations =>
      $$SoundEffectVariationsTableTableManager(
        _db.attachedDatabase,
        _db.soundEffectVariations,
      );
  $$AmbienceAssetsTableTableManager get ambienceAssets =>
      $$AmbienceAssetsTableTableManager(
        _db.attachedDatabase,
        _db.ambienceAssets,
      );
  $$AmbienceLayersTableTableManager get ambienceLayers =>
      $$AmbienceLayersTableTableManager(
        _db.attachedDatabase,
        _db.ambienceLayers,
      );
  $$AmbienceVariantsTableTableManager get ambienceVariants =>
      $$AmbienceVariantsTableTableManager(
        _db.attachedDatabase,
        _db.ambienceVariants,
      );
  $$MusicCuesTableTableManager get musicCues =>
      $$MusicCuesTableTableManager(_db.attachedDatabase, _db.musicCues);
  $$MusicSectionsTableTableManager get musicSections =>
      $$MusicSectionsTableTableManager(_db.attachedDatabase, _db.musicSections);
}
