import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/cinema/domain/rendering.dart';
import 'package:void_scriptor/features/cinema/domain/subtitles.dart';
import 'package:void_scriptor/features/cinema/domain/review.dart';

void main() {
  group('RenderPreset', () {
    test('holds render preset', () {
      const preset = RenderPreset(
        id: 'rp1',
        name: 'Cinematic 4K',
        frameRate: 24,
        aspectRatio: '16:9',
      );
      expect(preset.frameRate, 24);
      expect(preset.aspectRatio, '16:9');
    });
  });

  group('RenderQueueJob', () {
    test('holds render job state', () {
      const job = RenderQueueJob(
        id: 'j1',
        cinematicId: 'c1',
        presetId: 'rp1',
        status: RenderStatus.queued,
      );
      expect(job.status, RenderStatus.queued);
    });
  });

  group('SubtitleTrack', () {
    test('holds subtitle cues', () {
      const track = SubtitleTrack(
        id: 'st1',
        cinematicId: 'c1',
        language: 'id',
        cues: [
          SubtitleCue(
            id: 'cue1',
            startMs: 1000,
            endMs: 3000,
            text: 'Void bangkit.',
          ),
        ],
      );
      expect(track.language, 'id');
      expect(track.cues.first.text, 'Void bangkit.');
    });
  });

  group('ShotVersion', () {
    test('holds shot version', () {
      const v = ShotVersion(
        id: 'v1',
        shotId: 's1',
        versionNumber: 3,
        renderPresetId: 'rp1',
      );
      expect(v.versionNumber, 3);
    });
  });

  group('ReviewComment', () {
    test('holds review comment', () {
      final c = ReviewComment(
        id: 'rc1',
        shotId: 's1',
        author: 'Choirudin',
        text: 'Tambah kontras pada adegan malam.',
        createdAt: DateTime.utc(2026, 1, 1),
      );
      expect(c.author, 'Choirudin');
      expect(c.text, contains('kontras'));
    });
  });

  group('ShotStatus', () {
    test('exposes production statuses', () {
      expect(ShotStatus.values.map((e) => e.name), [
        'concept',
        'storyboard',
        'blocking',
        'animating',
        'lighting',
        'rendering',
        'review',
        'approved',
        'finalCut',
      ]);
    });
  });
}
