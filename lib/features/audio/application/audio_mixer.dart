import '../../audio_timeline/domain/audio_timeline_models.dart';

/// Ducking metadata (Step 23.36).
///
/// When a trigger track (e.g. dialogue) is active, a ducked track (e.g. music)
/// is lowered by [duckAmountDb].
class DuckingMetadata {
  const DuckingMetadata({
    required this.duckedTrack,
    required this.triggerTrack,
    required this.duckAmountDb,
  });

  final AudioTrackType duckedTrack;
  final AudioTrackType triggerTrack;
  final double duckAmountDb;
}

/// Scene audio mix summary (Step 23.35).
class SceneAudioMix {
  const SceneAudioMix({required this.clipsByTrack});

  final Map<AudioTrackType, List<AudioTimelineClipModel>> clipsByTrack;

  Set<AudioTrackType> get trackTypes => clipsByTrack.keys.toSet();

  int clipCountFor(AudioTrackType type) => clipsByTrack[type]?.length ?? 0;
}

/// Audio mixer (Step 23.34).
///
/// Resolves the audible gain for each track given mute/solo state and ducking
/// metadata. This is the deterministic decision model — actual audio playback
/// stays behind the platform player boundary.
class AudioMixer {
  const AudioMixer();

  double trackGainDb(
    AudioTrackType track, {
    required bool mute,
    AudioTrackType? solo,
  }) {
    if (solo != null) {
      return solo == track ? 0 : double.negativeInfinity;
    }
    return mute ? double.negativeInfinity : 0;
  }

  double applyDucking({
    required double baseGainDb,
    required DuckingMetadata metadata,
    required bool triggerActive,
  }) {
    if (!triggerActive) return baseGainDb;
    return baseGainDb - metadata.duckAmountDb;
  }

  SceneAudioMix buildSceneMix(Iterable<AudioTimelineClipModel> clips) {
    final byTrack = <AudioTrackType, List<AudioTimelineClipModel>>{};
    for (final clip in clips) {
      byTrack.putIfAbsent(clip.trackType, () => []).add(clip);
    }
    return SceneAudioMix(clipsByTrack: byTrack);
  }
}
