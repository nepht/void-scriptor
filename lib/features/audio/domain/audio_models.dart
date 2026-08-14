enum SoundEffectCategory {
  impact,
  weapon,
  movement,
  footsteps,
  technology,
  creature,
  vehicle,
  environment,
  destruction,
  interface,
  magic,
  voidEffect,
  other,
}

enum MusicMood {
  neutral,
  peaceful,
  emotional,
  romantic,
  mysterious,
  tension,
  action,
  heroic,
  dark,
  tragic,
  triumphant,
}

class AudioFileModel {
  const AudioFileModel({
    required this.id,
    required this.projectId,
    required this.filePath,
    this.contentHash,
    this.durationSeconds,
    this.sampleRate,
    this.channels,
  });
  final String id, projectId, filePath;
  final String? contentHash;
  final double? durationSeconds;
  final int? sampleRate, channels;
}

class SoundEffectModel {
  const SoundEffectModel({
    required this.assetId,
    required this.projectId,
    required this.name,
    required this.category,
    this.audioFileId,
    this.description = '',
    this.loopable = false,
  });
  final String assetId, projectId, name, description;
  final String? audioFileId;
  final SoundEffectCategory category;
  final bool loopable;
}

class SoundEffectVariationModel {
  const SoundEffectVariationModel({
    required this.id,
    required this.soundEffectId,
    required this.audioFileId,
    this.label = '',
    this.weight = 1,
  });
  final String id, soundEffectId, audioFileId, label;
  final double weight;
}

class AmbienceModel {
  const AmbienceModel({
    required this.assetId,
    required this.projectId,
    required this.name,
    this.audioFileId,
    this.description = '',
    this.loopable = true,
  });
  final String assetId, projectId, name, description;
  final String? audioFileId;
  final bool loopable;
}

class AmbienceLayerModel {
  const AmbienceLayerModel({
    required this.id,
    required this.ambienceId,
    required this.audioFileId,
    required this.name,
    this.defaultGainDb = 0,
    this.sortOrder = 0,
  });
  final String id, ambienceId, audioFileId, name;
  final double defaultGainDb;
  final int sortOrder;
}

class AmbienceVariantModel {
  const AmbienceVariantModel({
    required this.id,
    required this.ambienceId,
    required this.name,
    this.referenceAudioFileId,
    this.conditions = '',
  });
  final String id, ambienceId, name, conditions;
  final String? referenceAudioFileId;
}

class MusicCueModel {
  const MusicCueModel({
    required this.assetId,
    required this.projectId,
    required this.name,
    required this.mood,
    this.audioFileId,
    this.bpm,
    this.musicalKey,
    this.description = '',
    this.loopable = false,
  });
  final String assetId, projectId, name, description;
  final String? audioFileId, musicalKey;
  final MusicMood mood;
  final double? bpm;
  final bool loopable;
}

class MusicSectionModel {
  const MusicSectionModel({
    required this.id,
    required this.musicId,
    required this.name,
    required this.startSeconds,
    required this.endSeconds,
    this.mood,
  });
  final String id, musicId, name;
  final double startSeconds, endSeconds;
  final MusicMood? mood;
}
