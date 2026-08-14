enum AudioTrackType { dialogue, soundEffect, ambience, music }

enum MusicIntent { startTheme, continueTheme, transition, endTheme, stinger }

class AudioTimelineClipModel {
  const AudioTimelineClipModel({
    required this.id,
    required this.timelineId,
    required this.trackType,
    required this.audioFileId,
    required this.startSeconds,
    required this.durationSeconds,
    this.fadeInSeconds = 0,
    this.fadeOutSeconds = 0,
    this.gainDb = 0,
    this.pan = 0,
    this.intent,
  });
  final String id, timelineId, audioFileId;
  final AudioTrackType trackType;
  final double startSeconds,
      durationSeconds,
      fadeInSeconds,
      fadeOutSeconds,
      gainDb,
      pan;
  final MusicIntent? intent;
}

class AudioAutomationKeyframeModel {
  const AudioAutomationKeyframeModel({
    required this.id,
    required this.clipId,
    required this.timeSeconds,
    required this.parameter,
    required this.value,
  });
  final String id, clipId, parameter;
  final double timeSeconds, value;
}
