import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/cinema/domain/camera.dart';
import 'package:void_scriptor/features/cinema/domain/cinema_project.dart';
import 'package:void_scriptor/features/cinema/domain/grammar.dart';
import 'package:void_scriptor/features/cinema/domain/performance.dart';
import 'package:void_scriptor/features/cinema/domain/dialogue.dart';

void main() {
  group('VirtualCamera', () {
    test('holds camera position and mode', () {
      const cam = VirtualCamera(
        id: 'cam1',
        shotId: 's1',
        preset: CameraPreset.medium,
      );
      expect(cam.preset, CameraPreset.medium);
      expect(cam.movement, CameraMovement.static);
    });
  });

  group('CameraMovement', () {
    test('exposes camera movements', () {
      expect(CameraMovement.values.map((e) => e.name), [
        'static',
        'pan',
        'tilt',
        'dolly',
        'track',
        'crane',
        'zoom',
        'handheld',
        'orbit',
      ]);
    });
  });

  group('CinematicGrammar', () {
    test('exposes grammar rules', () {
      expect(GrammarRule.values.map((e) => e.name), [
        'shotReverseShot',
        'thirtyDegree',
        'eyelineMatch',
        'ruleOfThirds',
        'talkingHeads',
        'actionAxis',
      ]);
    });
  });

  group('ContinuityRule', () {
    test('holds continuity rule', () {
      const rule = ContinuityRule(
        id: 'r1',
        description: 'Watch position must match screen direction',
        allowBreak: false,
      );
      expect(rule.allowBreak, isFalse);
    });
  });

  group('PerformanceCurve', () {
    test('samples curve at t', () {
      final curve = PerformanceCurve(
        id: 'p1',
        points: {0.0: 0.0, 0.5: 0.8, 1.0: 0.2},
      );
      expect(curve.sample(0.0), 0.0);
      expect(curve.sample(1.0), 0.2);
      expect(curve.sample(0.5), 0.8);
    });
  });

  group('DialogueClip', () {
    test('holds dialogue timing', () {
      const clip = DialogueClip(
        id: 'd1',
        shotId: 's1',
        characterId: 'char1',
        text: 'The Void awakens.',
        startSeconds: 2.0,
        endSeconds: 5.0,
      );
      expect(clip.durationSeconds, 3.0);
      expect(clip.text, contains('Void'));
    });
  });
}
