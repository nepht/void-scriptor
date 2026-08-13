import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/timeline/application/timeline_context_service.dart';
import 'package:void_scriptor/features/timeline/domain/timeline_model.dart';

void main() {
  test('resolved context returns active clips at playhead', () {
    final context = resolveTimelineContext(
      timeSeconds: 4.5,
      clips: const [
        TimelineClipModel(
          id: 'a',
          trackId: 'action',
          startSeconds: 0,
          durationSeconds: 5,
          label: 'Impact',
        ),
        TimelineClipModel(
          id: 'b',
          trackId: 'vfx',
          startSeconds: 4,
          durationSeconds: 1,
          label: 'Shockwave',
        ),
        TimelineClipModel(
          id: 'c',
          trackId: 'audio',
          startSeconds: 8,
          durationSeconds: 1,
          label: 'Debris',
        ),
      ],
    );
    expect(context.activeClipIds, ['a', 'b']);
  });

  test('timeline export produces portable JSON', () {
    final json = exportTimelineJson(
      sceneId: 'scene-1',
      durationSeconds: 10,
      frameRate: 30,
      tracks: const [],
      clips: const [],
    );
    final decoded = jsonDecode(json) as Map<String, dynamic>;
    expect(decoded['sceneId'], 'scene-1');
    expect(decoded['duration'], 10);
    expect(decoded['fps'], 30);
  });
}
