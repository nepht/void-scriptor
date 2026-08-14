// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audio_import_repository.dart';

// ignore_for_file: type=lint
mixin _$AudioImportRepositoryMixin on DatabaseAccessor<ProjectDatabase> {
  $AudioFilesTable get audioFiles => attachedDatabase.audioFiles;
  $AudioWaveformCachesTable get audioWaveformCaches =>
      attachedDatabase.audioWaveformCaches;
  AudioImportRepositoryManager get managers =>
      AudioImportRepositoryManager(this);
}

class AudioImportRepositoryManager {
  final _$AudioImportRepositoryMixin _db;
  AudioImportRepositoryManager(this._db);
  $$AudioFilesTableTableManager get audioFiles =>
      $$AudioFilesTableTableManager(_db.attachedDatabase, _db.audioFiles);
  $$AudioWaveformCachesTableTableManager get audioWaveformCaches =>
      $$AudioWaveformCachesTableTableManager(
        _db.attachedDatabase,
        _db.audioWaveformCaches,
      );
}
