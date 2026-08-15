import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/audio/application/audio_mixer.dart';
import 'package:void_scriptor/features/audio_timeline/domain/audio_timeline_models.dart';

void main() {
  test('mixer resolves per-track gain with mute and solo', () {
    const mixer = AudioMixer();

    expect(
      mixer.trackGainDb(AudioTrackType.dialogue, mute: false, solo: null),
      0.0,
    );
    expect(
      mixer.trackGainDb(AudioTrackType.dialogue, mute: true, solo: null),
      double.negativeInfinity,
    );
    // Solo overrides mute; only the soloed track is audible.
    expect(
      mixer.trackGainDb(
        AudioTrackType.dialogue,
        mute: true,
        solo: AudioTrackType.dialogue,
      ),
      0.0,
    );
    expect(
      mixer.trackGainDb(
        AudioTrackType.music,
        mute: false,
        solo: AudioTrackType.dialogue,
      ),
      double.negativeInfinity,
    );
  });

  test('ducking metadata lowers music gain under dialogue', () {
    const ducking = DuckingMetadata(
      duckedTrack: AudioTrackType.music,
      triggerTrack: AudioTrackType.dialogue,
      duckAmountDb: 6,
    );
    const mixer = AudioMixer();

    final level = mixer.applyDucking(
      baseGainDb: 0,
      metadata: ducking,
      triggerActive: true,
    );

    expect(level, -6);
  });

  test('ducking releases when trigger is inactive', () {
    const ducking = DuckingMetadata(
      duckedTrack: AudioTrackType.music,
      triggerTrack: AudioTrackType.dialogue,
      duckAmountDb: 6,
    );
    const mixer = AudioMixer();
    expect(
      mixer.applyDucking(
        baseGainDb: 0,
        metadata: ducking,
        triggerActive: false,
      ),
      0,
    );
  });

  test('scene mix aggregates clips per track type', () {
    final clips = [
      const AudioTimelineClipModel(
        id: 'c1',
        timelineId: 't1',
        trackType: AudioTrackType.dialogue,
        audioFileId: 'a1',
        startSeconds: 0,
        durationSeconds: 2,
      ),
      const AudioTimelineClipModel(
        id: 'c2',
        timelineId: 't1',
        trackType: AudioTrackType.music,
        audioFileId: 'a2',
        startSeconds: 0,
        durationSeconds: 2,
      ),
    ];
    const mixer = AudioMixer();
    final mix = mixer.buildSceneMix(clips);

    expect(
      mix.trackTypes,
      containsAll([AudioTrackType.dialogue, AudioTrackType.music]),
    );
    expect(mix.clipCountFor(AudioTrackType.dialogue), 1);
    expect(mix.clipCountFor(AudioTrackType.music), 1);
  });
}
