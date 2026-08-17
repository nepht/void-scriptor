import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/cinema/domain/cinema_project.dart';

void main() {
  group('CinematicProject', () {
    test('creates cinematic project', () {
      final p = CinematicProject(
        id: 'c1',
        name: 'Void Cube: Prologue',
        type: CinematicType.film,
      );
      expect(p.name, 'Void Cube: Prologue');
      expect(p.type, CinematicType.film);
      expect(p.shots, isEmpty);
    });
  });

  group('CinematicType', () {
    test('exposes cinematic types', () {
      expect(CinematicType.values.map((e) => e.name), [
        'film',
        'episode',
        'cutscene',
        'trailer',
        'interactive',
        'machinima',
      ]);
    });
  });

  group('CinematicShot', () {
    test('holds shot metadata', () {
      const shot = CinematicShot(
        id: 's1',
        cinematicId: 'c1',
        name: 'Opening Wide',
        order: 1,
        durationSeconds: 8.0,
      );
      expect(shot.name, 'Opening Wide');
      expect(shot.order, 1);
      expect(shot.durationSeconds, 8.0);
    });
  });

  group('CameraPreset', () {
    test('exposes camera presets', () {
      expect(CameraPreset.values.map((e) => e.name), [
        'wide',
        'medium',
        'closeUp',
        'extremeCloseUp',
        'overShoulder',
        'pov',
        'aerial',
        'establishing',
      ]);
    });
  });

  group('TrackType', () {
    test('exposes track types', () {
      expect(TrackType.values.map((e) => e.name), [
        'video',
        'camera',
        'audio',
        'dialogue',
        'vfx',
        'subtitle',
      ]);
    });
  });
}
